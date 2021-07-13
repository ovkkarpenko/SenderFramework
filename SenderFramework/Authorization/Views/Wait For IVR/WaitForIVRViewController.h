//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegistrationViewController.h"

@protocol MWSenderFullAuthorizationPresenterEventHandler;

@interface WaitForIVRViewController : RegistrationViewController <MWSenderFullAuthorizationPresenterEventHandler>

@property (nonatomic, strong) NSDictionary * incomingMessage;

- (void)customizeViewForIVR:(NSDictionary *)response;

@end