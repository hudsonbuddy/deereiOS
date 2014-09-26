//
//  DummyPeripheralServer.h
//  DeereBTDemo
//
//  Created by Colin Hom on 4/23/14.
//  Copyright (c) 2014 Hudson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol CanPeripheralServerDelegate;

@interface CanAlertPeripheralServer : NSObject
@property(nonatomic,assign) id<CanPeripheralServerDelegate> delegate;

@property(nonatomic,strong) NSString *serviceName;
@property(nonatomic,strong) CBUUID *serviceUUID;

enum UpdateType
{
    UNKNOWN = -1,
    DFMARGIN,
    RIDEQUAL,
    COV,
    SINGULATION,
    ACTPOP
};
- (id)initWithDelegate:(id<CanPeripheralServerDelegate>)delegate;

/*
   rowSize: how many rows this tractor has
 
   **note - no longer called when bluetooth power on message received... must call explicitly
 */
- (void)start:(NSUInteger) rowSize;

- (void)stop;

/*
    type : type of parameter
    value : composite parameter value
    rowData : NSArray of BOOL
    locationData : 3-element NSArray of floats [lat, long, heading]
*/
- (void)update:(enum UpdateType) type withValue:(Float32) value withRowData:(NSArray*) rowData withLocationData:(NSArray*) locationData;

- (void)alert:(enum UpdateType) type withColor:(uint8_t) color;


@end

@protocol CanPeripheralServerDelegate <NSObject>
- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onCentralSubscribe:(CBCentral *)central;
- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onCentralUnsubscribe:(CBCentral *)central;
- (void)peripheralServer:(CanAlertPeripheralServer *)peripheral onConnectionError:(NSString *)msg;
@end