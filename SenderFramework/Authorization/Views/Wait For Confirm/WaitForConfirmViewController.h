//
//  WaitForConfirmViewController.h
//  SENDER
//
//  Created by Roman Serga on 13/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "RegistrationViewController.h"

@protocol MWSenderFullAuthorizationPresenterEventHandler;

@interface WaitForConfirmViewController : RegistrationViewController <MWSenderFullAuthorizationPresenterEventHandler>

@property (nonatomic, strong) NSString * deviceName;

@end
