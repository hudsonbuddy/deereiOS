//
//  StatBox.h
//  DeereBTDriver
//
//  Created by Colin Hom on 5/8/14.
//  Copyright (c) 2014 repco. All rights reserved.
//

#import <Foundation/Foundation.h>
#define LAT_CACHE_COUNT 3
#define HISTORY_SIZE 20
#define ALERT_MAX 8


@interface StatBox : NSObject
- (id) initWithRowSize:(size_t) rowSize;
- (NSData *) getResponseBuffer:(NSUUID*) centralId withReadOffset:(NSInteger) offset;
- (BOOL) pushSample:(Float32) value withRowData:(NSArray *)rowData withLocationData: (NSArray *)locationData;
- (BOOL) pushAlert:(uint8_t) alertColor;
@end
