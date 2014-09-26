//
//  DummyPeripheralServer.m
//  DeereBTDemo
//
//  Created by Colin Hom on 4/23/14.
//  Copyright (c) 2014 Hudson. All rights reserved.
//

#import "CanAlertPeripheralServer.h"
#import "StatBox.h"
@interface CanAlertPeripheralServer () <
    CBPeripheralManagerDelegate>
@property(nonatomic,strong) NSArray *UUIDS;
@property(nonatomic,strong) CBPeripheralManager *peripheral;
@property(nonatomic,strong) CBMutableService *service;
@property(nonatomic,strong) NSData *pendingData;
@property(nonatomic,strong) NSMutableArray *characteristics;
@property(nonatomic,strong) NSMutableArray *values;
@property(atomic,strong) dispatch_queue_t statQueue;

@property NSUInteger rowSize;
@end

@implementation CanAlertPeripheralServer

- (id)init {
    @throw [NSException exceptionWithName:@"BadInitialization" reason:@"Must provide delegate using initWithDelegate" userInfo:nil];
    return nil;
}

- (id)initWithDelegate:(id<CanPeripheralServerDelegate>)delegate{
    self = [super init];

    self.statQueue = dispatch_queue_create("com.repco.deere.glass.STATQUEUE", NULL);
    
    self.peripheral =
        [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    self.delegate = delegate;


   self.UUIDS = [[NSArray alloc] initWithObjects:
                            @"deadbeef-dead-beef-dead-000000000001",
                            @"deadbeef-dead-beef-dead-000000000002",
                            @"deadbeef-dead-beef-dead-000000000003",
                            @"deadbeef-dead-beef-dead-000000000004",
                            @"deadbeef-dead-beef-dead-000000000005",
                  nil];

    self.characteristics =[[NSMutableArray alloc] initWithCapacity:[self.UUIDS count]];
    self.values = [[NSMutableArray alloc] initWithCapacity:[self.UUIDS count]];

    return self;
    
}
- (void)start:(NSUInteger) rowSize{
    //just to make sure
    if (self.service){
        [self.peripheral removeService:self.service];
    }
    self.rowSize = rowSize;
    
    //initialize characterstics and stat boxes
    for(int i=0; i< [self.UUIDS count]; i++){
        CBUUID *uuid = [CBUUID UUIDWithString:[self.UUIDS objectAtIndex:i]];
        
        CBMutableCharacteristic *cb = [[CBMutableCharacteristic alloc] initWithType:uuid properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
        
        [self.characteristics setObject:cb atIndexedSubscript:i];
        [self.values setObject:[[StatBox alloc] initWithRowSize:self.rowSize] atIndexedSubscript:i];
    }
    
    //begin bluetooth initialization

    self.serviceName = @"GlassDeere";
    self.serviceUUID = [CBUUID UUIDWithString:@"deadbeef-dead-beef-dead-badb100dbeef"];
    
    NSLog(@"Adding service %@",self.serviceUUID);
    self.service = [[CBMutableService alloc] initWithType:self.serviceUUID primary:YES];
    

    self.service.characteristics = self.characteristics;
    
    [self.peripheral addService:self.service];
    
}

- (void)stop{
    NSLog(@"Removing service %@",self.serviceUUID);
    [self.peripheral removeService:self.service];
    self.service = nil;
    [self.peripheral stopAdvertising];
}

- (void)updateCharacteristic:(CBMutableCharacteristic *)characteristic updateValue:(NSData *)data{
    
    BOOL success = [self.peripheral updateValue:data forCharacteristic:characteristic onSubscribedCentrals:nil];
    
    if (!success){
        [self.delegate peripheralServer:self onConnectionError:@"Data send failed"];
    }
}
- (void)update:(enum UpdateType)type withValue:(Float32)value withRowData:(NSArray*) rowData withLocationData:(NSArray*) locationData{
    if (type != UNKNOWN){
        dispatch_async(self.statQueue, ^{
            StatBox *stats = [self.values objectAtIndex:type];
            [stats pushSample:value withRowData:rowData withLocationData:locationData];
        });
    }
}

- (void)alert:(enum UpdateType)type withColor:(uint8_t)color{
    if (type != UNKNOWN){
        dispatch_async(self.statQueue, ^{
            StatBox *stats = [self.values objectAtIndex:type];
            if ([stats pushAlert:color]){
                [self updateCharacteristic:[self.characteristics objectAtIndex:type] updateValue:[[NSData alloc]init]];
            }
        });
    }

}
#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    
    //This is how we start advertising
    if (self.peripheral.isAdvertising){
        [self.peripheral stopAdvertising];
    }
    
    NSDictionary *advertisment = @{
                                   CBAdvertisementDataServiceUUIDsKey : @[self.serviceUUID],
                                   CBAdvertisementDataLocalNameKey : self.serviceName
                    };
    
    [self.peripheral startAdvertising:advertisment];
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"peripheralStateChange: Powered On");
            break;
        case CBPeripheralManagerStatePoweredOff: {
            NSLog(@"peripheralStateChange: Powered Off");
            [self stop];
            break;
        }
        case CBPeripheralManagerStateResetting: {
            NSLog(@"peripheralStateChange: Resetting");
            break;
        }
        case CBPeripheralManagerStateUnauthorized: {
            NSLog(@"peripheralStateChange: Deauthorized");
            [self stop];
            break;
        }
        case CBPeripheralManagerStateUnsupported: {
            NSLog(@"peripheralStateChange: Unsupported");
            [self.delegate peripheralServer:self onConnectionError:@"Bluetooth LE is not supported on this device"];
            break;
        }
        case CBPeripheralManagerStateUnknown:
            NSLog(@"peripheralStateChange: Unknown");
            break;
        default:
            break;
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    central:(CBCentral *)central
    didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didSubscribe: %@", characteristic.UUID);
    NSLog(@"didSubscribe: - Central: %@", central.identifier);
    [self.delegate peripheralServer:self onCentralSubscribe:central];
}
    
- (void)peripheralManager:(CBPeripheralManager *)peripheral
    central:(CBCentral *)central
    didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"didUnsubscribe: %@", central.identifier);
    [self.delegate peripheralServer:self onCentralUnsubscribe:central];
}
    
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    if (error) {
        NSLog(@"didStartAdvertising: Error: %@", error);
        [self.delegate peripheralServer:self onConnectionError:[NSString stringWithFormat:@"BT advertisment error: %@",error]];
        return;
    }
    NSLog(@"didStartAdvertising");
}
    
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"isReadyToUpdateSubscribers");
/*
    if (self.pendingData) {
        NSData *data = [self.pendingData copy];
        self.pendingData = nil;
        [self sendToSubscribers:data];
    }
 */
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"ReadRequest %@",request);
    enum UpdateType type;
    for(type = 0 ; type < [self.characteristics count]; type ++){
        if ([request.characteristic.UUID isEqual:((CBMutableCharacteristic*)[self.characteristics objectAtIndex:type]).UUID]){
            break;
        }
    }
    if (type >= [self.characteristics count]){
        NSLog(@"Could not find type for UUID %@",request.characteristic.UUID);
        [peripheral respondToRequest:request withResult:CBATTErrorUnlikelyError];
        return;
    }
    dispatch_async(self.statQueue, ^{
        StatBox *stats = [self.values objectAtIndex:type];
        NSData *value = [stats getResponseBuffer:request.central.identifier withReadOffset:request.offset];
    
        if (request.offset > value.length){
            [peripheral respondToRequest:request withResult:CBATTErrorInvalidOffset];
            return;
        }
    
        request.value = [value subdataWithRange:NSMakeRange(request.offset, value.length - request.offset)];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    });
}

@end
