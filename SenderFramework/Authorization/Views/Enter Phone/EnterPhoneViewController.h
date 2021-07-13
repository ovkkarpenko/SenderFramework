//
//  EnterPhoneViewController.h
//  SENDER
//
//  Created by Roman Serga on 19/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TermsConditionsViewController.h"
#import "RegistrationViewController.h"

@protocol TermsConditionsModuleDelegate;
@protocol EnterPhonePrefixViewControllerDelegate;

@interface EnterPhoneViewController : RegistrationViewController <UITextFieldDelegate,
        TermsConditionsModuleDelegate, EnterPhonePrefixViewControllerDelegate>

@property (nonatomic, strong) NSDictionary * incommingMessge;

- (void)setRegisterButtonEnabled:(BOOL)enabled;

@end
