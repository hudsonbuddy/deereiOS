//
//  AppDelegate.m
//  DeereBTDemo
//
//  Created by Hudson on 4/14/14.
//  Copyright (c) 2014 Hudson. All rights reserved.
//

#import "AppDelegate.h"
#import "CanAlertPeripheralServer.h"
#import "ViewController.h"
#import "StatBox.h"

#define ROW_SIZE 24
@interface AppDelegate () <CanPeripheralServerDelegate>
@property (nonatomic,strong) CanAlertPeripheralServer *peripheral;
@property (nonatomic,strong) ViewController *viewController;
@property (nonatomic,strong) NSArray *locationData;
@property (nonatomic,strong) NSMutableArray *rowData;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.peripheral stop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void) getRandomRow:(NSMutableArray*)rowData{
    for(int i = 0; i < ROW_SIZE ; i++){
        NSInteger val = arc4random();
        if(val < ARC4RANDOM_MAX / 40){
            rowData[i] = @true;
        }else{
            rowData[i] = @false;
        }
    }
    
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    //set up observer FIRST to avoid startup drop
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBroadcastMessage:) name:@"sendAlert" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBroadcastMessage:) name:@"sendValue" object:nil];
    NSLog(@"Setting up peripheral service");
    
    self.peripheral =[[CanAlertPeripheralServer alloc ] initWithDelegate:self];
    [self.peripheral start:ROW_SIZE];
    self.locationData = @[@37.8609611111,@122.275158333,@90.00];
    self.rowData = [[NSMutableArray alloc] initWithCapacity:ROW_SIZE];
    for (int i= 0; i < ROW_SIZE; i++) {
        [self.rowData addObject:@false];
    }
    
    //prime some bogus values
    for(enum UpdateType param = DFMARGIN; param <= ACTPOP ; param ++ ){

        [self getRandomRow:self.rowData];
        
        for(int i = 0; i < 20;i++){
            [self.peripheral update:param withValue:((Float32)arc4random() / ARC4RANDOM_MAX)*100.0 withRowData:self.rowData withLocationData:self.locationData];
        }
    }
    
    
    
    
}
- (void)handleBroadcastMessage:(NSNotification *)note{
    NSDictionary *data = [note userInfo];
    NSLog(@"Handle broadcast %@",note.name);
    if ([note.name isEqualToString:@"sendAlert"]){
        NSString *msg = [data objectForKey:@"msg"];
    
        NSLog(@"handle message %@",msg);
        enum UpdateType paramType;
        if([msg isEqual:@"df_margin1"]){
            paramType = DFMARGIN;
        }else if([msg isEqual:@"cov"]){
            paramType = COV;
        }else if([msg isEqual:@"act_pop"]){
            paramType = ACTPOP;
        }else if([msg isEqual:@"ridequal"]){
            paramType = RIDEQUAL;
        }else if([msg isEqual:@"singulation"]){
            paramType = SINGULATION;
        }
        
        //Send 5 red alerts for this parameter to trigger an event on glass
        for(int i= 0 ;  i < ALERT_MAX; i++){
            [self.peripheral alert:paramType withColor:0x02];
        }
    }else if([note.name isEqualToString:@"sendValue"]){
        NSNumber *val = [data objectForKey:@"value"];
        NSString *param = [data objectForKey:@"param"];
        NSLog(@"recevied send value %@ %@",val,param);
        
        enum UpdateType paramType = -1;
        if([param isEqualToString:@"dfmargin1"]){
            paramType = DFMARGIN;
        }else if([param isEqualToString:@"cov"]){
            paramType = COV;
        }else if([param isEqualToString:@"actpop"]){
            paramType = ACTPOP;
        }else if([param isEqualToString:@"ridequal"]){
            paramType = RIDEQUAL;
        }else if([param isEqualToString:@"singulation"]){
            paramType = SINGULATION;
        }
        
        [self getRandomRow:self.rowData];
        [self.peripheral update:paramType withValue:[val floatValue] withRowData:self.rowData withLocationData:self.locationData];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
#pragma mark - DummyPeripheralServerDelegate

- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onCentralSubscribe:(CBCentral *)central{
    [self.viewController onConnectionEvent:[NSString stringWithFormat:@"%@ has connected",[central.identifier UUIDString]]];
}

- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onCentralUnsubscribe:(CBCentral *)central{
    [self.viewController onConnectionEvent:[NSString stringWithFormat:@"%@ has disconnected",[central.identifier UUIDString]]];
}

- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onConnectionError:(NSString *)msg{
    NSLog(@"onConnectionError: %@",msg);
    [self.viewController onConnectionEvent:[NSString stringWithFormat:@"Bluetooth Error: %@",msg]];
}

@end
