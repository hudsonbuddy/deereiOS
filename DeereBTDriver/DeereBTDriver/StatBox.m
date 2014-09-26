//
//  StatBox.m
//  DeereBTDriver
//
//  Created by Colin Hom on 5/8/14.
//  Copyright (c) 2014 repco. All rights reserved.
//
#import "float.h"
#import "StatBox.h"

typedef struct __attribute__((packed)) {
    Float32 current;
    Float32 ave;
    Float32 max;
    Float32 min;
    Float32 percentChange;
    uint8_t color;
    
} summary_data_t;

@interface StatBox()
@property(nonatomic) Float32 *history;
@property(nonatomic) NSMutableArray *rowCache;
@property(nonatomic) NSMutableArray *latCache;
@property(nonatomic) size_t rowSize;
@property(nonatomic) int ptr;
@property(nonatomic) uint8_t alertColor;
@property(nonatomic) size_t alertCount;
@property(nonatomic,strong) NSDictionary *responseMap;
@end

@implementation StatBox

- (id)init {
    @throw [NSException exceptionWithName:@"BadInitialization" reason:@"Must use initWithRowSize" userInfo:nil];
    return nil;
}
- (id)initWithRowSize:(size_t)rowSize{
    self = [super init];
    self.history = malloc(sizeof(Float32)*HISTORY_SIZE);
    self.rowSize = rowSize;
    self.rowCache = [[NSMutableArray alloc] initWithCapacity:rowSize];
    for (int i = 0; i < rowSize; i++) {
        [self.rowCache addObject:[NSNumber numberWithInt:0]];
    }
    self.latCache = [[NSMutableArray alloc] initWithCapacity:LAT_CACHE_COUNT];
    self.ptr = 0;
    self.alertCount = 0;
    self.alertColor = 0;
    
    self.responseMap = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc{
    if(self.history != nil){
        free(self.history);
        self.history = nil;
    }


}
- (BOOL)pushSample:(Float32)value withRowData:(NSArray *)rowData withLocationData:(NSArray *)locationData{
    self.ptr = (self.ptr + 1) % HISTORY_SIZE;
    self.history[self.ptr] = value;
    
    //update row values
    
    for(int i = 0; i < self.rowSize ; i++){
        NSInteger current = [(NSNumber*)self.rowCache[i] integerValue];

        BOOL problem = [(NSNumber*)rowData[i] boolValue];
        
        //bad rows will be flagged for ALERT_MAX cycles
        if (problem){
            current = ALERT_MAX;
        }else{
            if(current > 0){
                current --;
            }
        }
        //write new row cache value in
        self.rowCache[i] = [NSNumber numberWithInteger:current];
    }

    
    //copy over locatoin values
    [self.latCache removeAllObjects];
    [self.latCache addObjectsFromArray:locationData];
    
    if(false){
        // TODO: custom value-based alerting logic
        return true;
    }
    return false;

}
- (BOOL)pushAlert:(uint8_t)alertColor{

    self.alertColor = alertColor;
    if(alertColor > 0x00){
        self.alertCount = (self.alertCount + 1)%ALERT_MAX;
        if (self.alertCount == 0){
            return true;
        }
    }else{
        self.alertCount = 0;
    }
    return false;
    
}

- (NSData*) getResponseBuffer:(NSUUID*) centralId withReadOffset:(NSInteger) offset{
    if(offset == 0){
        NSLog(@"Evicting: %@",[centralId UUIDString]);
        [self.responseMap setValue:[self getSummary] forKey:[centralId UUIDString]];
    }
    
    return [self.responseMap objectForKey:[centralId UUIDString]];
}

- (NSData*) getSummary{

    NSUInteger summarySize = sizeof(summary_data_t);
    NSUInteger locationSize =[self.latCache count]*sizeof(Float32);
    NSUInteger rowSize = [self.rowCache count]*sizeof(uint8_t);
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:summarySize+locationSize+rowSize];
    
    //Begin summary
    Float32 current = self.history[self.ptr];
    float ysum = 0;
    float xsum = 0;
    float xysum = 0;
    float x2sum =0;
    
    Float32 max = FLT_MIN;
    Float32 min = FLT_MAX;
    
    for(int i = 0; i < HISTORY_SIZE ; i++){
        float v = self.history[i];
        
        float x = (float) i;
        ysum += v;
        xsum += x;
        x2sum += x*x;
        xysum += v * x;
        
        if(v > max){
            max = v;
        }
        
        if(v < min){
            min = v;
        }
    }
    
    NSMutableData *summaryData = [NSMutableData dataWithLength:summarySize];
    summary_data_t *summary = [summaryData mutableBytes];
    
    summary->current = current;
    summary->ave = ysum / HISTORY_SIZE;
    summary->max = max;
    summary->min = min;
    
    float pcNum = (HISTORY_SIZE*xysum) - (xsum * ysum);
    float pcDenom = (HISTORY_SIZE*x2sum) - (xsum*xsum);
    if(pcDenom != 0.0){
        summary->percentChange = (pcNum * (HISTORY_SIZE - 1)) / (pcDenom * summary->ave);
    }else{
        summary->percentChange = 0.0;
    }

    summary->color = self.alertColor;
    
    //Begin location
    
    NSMutableData *locationData = [NSMutableData dataWithLength:locationSize];
    Float32 *location = [locationData mutableBytes];

    int writeHead = 0;
    
    for (NSNumber *latPoint in self.latCache){
        location[writeHead] = (Float32)[latPoint floatValue];
        writeHead ++;
    }
    
    
    //Begin row data
    NSMutableData *rowData = [NSMutableData dataWithLength:rowSize];
    uint8_t *row = [rowData mutableBytes];
    writeHead = 0;
    
    for (NSNumber *rowPoint in  self.rowCache){
        row[writeHead] = [rowPoint unsignedIntValue];
        writeHead ++;
    }
    
    //Mush all together
    [data appendData:summaryData];
    [data appendData:locationData];
    [data appendData:rowData];
    NSLog(@"getSummary %lu bytes",(unsigned long)data.length);
    return data;
    
}
@end
