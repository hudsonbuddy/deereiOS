//
//  ViewController.h
//  DeereBTDemo
//
//  Created by Hudson on 4/14/14.
//  Copyright (c) 2014 Hudson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
- (void)onConnectionEvent:(NSString *)msg;
@property (weak, nonatomic) IBOutlet UITextField *DFMARGIN1_OUTLET;
@property (weak, nonatomic) IBOutlet UITextField *DFMARGIN2_OUTLET;
@property (weak, nonatomic) IBOutlet UITextField *COV_OUTLET;
@property (weak, nonatomic) IBOutlet UITextField *ACTPOP_OUTLET;
@property (weak, nonatomic) IBOutlet UITextField *RIDEQUAL_OUTLET;
@property (weak, nonatomic) IBOutlet UITextField *SINGULATION_OUTLET;
@end
