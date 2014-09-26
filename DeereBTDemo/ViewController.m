//
//  ViewController.m
//  DeereBTDemo
//
//  Created by Hudson on 4/14/14.
//  Copyright (c) 2014 Hudson. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize DFMARGIN1_OUTLET;
@synthesize DFMARGIN2_OUTLET;
@synthesize COV_OUTLET;
@synthesize ACTPOP_OUTLET;
@synthesize RIDEQUAL_OUTLET;
@synthesize SINGULATION_OUTLET;

- (void)onConnectionEvent:(NSString *)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Update"
                                                    message:msg delegate:nil
                                                cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)ACT_POP:(id)sender {
    [self sendAlert:@"act_pop"];
}
- (IBAction)COV:(id)sender {
    [self sendAlert:@"cov"];
}
- (IBAction)DF_MARGIN1:(id)sender {
    [self sendAlert:@"df_margin1"];
}
- (IBAction)DF_MARGIN2:(id)sender {
    [self sendAlert:@"df_margin2"];
}
- (IBAction)RIDEQUAL:(id)sender {
    [self sendAlert:@"ridequal"];
}
- (IBAction)SINGULATION:(id)sender {
    [self sendAlert:@"singulation"];
}

- (void)sendAlert:(NSString *)msg{
    NSLog(@"sendAlert %@",msg);
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:msg forKey:@"msg"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sendAlert" object:self userInfo:dataDict];
}

- (void)sendValue:(NSNumber*) value forParam:(NSString*)param {
    NSLog(@"sendValue %@",value);
    if (value == nil){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid data"
                                                        message:@"Please enter a numerical value" delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:value,@"value",param,@"param" ,nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"sendValue" object:self userInfo:dataDict];
}

- (NSNumber*) getNumber:(id)sender{
     NSString *nums = [sender text];
    NSLog(@"Parse number from %@",nums);
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber * myNumber = [f numberFromString:nums];

    return myNumber;
}
- (IBAction)DFMARGIN1_SUBMIT:(id)sender {
    NSNumber *val = [self getNumber:DFMARGIN1_OUTLET];
    
    [self sendValue:val forParam:@"dfmargin1"];
}

- (IBAction)COV_SUBMIT:(id)sender {
    NSNumber *val = [self getNumber:COV_OUTLET];
    
    [self sendValue:val forParam:@"cov"];
}
- (IBAction)ACTPOP_SUBMIT:(id)sender {
    NSNumber *val = [self getNumber:ACTPOP_OUTLET];
    
    [self sendValue:val forParam:@"actpop"];
}

- (IBAction)RIDEQUAL_SUBMIT:(id)sender {
    NSNumber *val = [self getNumber:RIDEQUAL_OUTLET];
    
    [self sendValue:val forParam:@"ridequal"];
}
- (IBAction)SINGULATION_SUBMIT:(id)sender {
    NSNumber *val = [self getNumber:SINGULATION_OUTLET];
    
    [self sendValue:val forParam:@"singulation"];
}

@end
