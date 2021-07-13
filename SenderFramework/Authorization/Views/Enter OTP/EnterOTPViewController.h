//
//  EnterOTPViewController.h
//  SENDER
//
//  Created by Roman Serga on 20/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegistrationViewController.h"

@interface EnterOTPViewController : RegistrationViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSDictionary * incomingMessage;

@end
