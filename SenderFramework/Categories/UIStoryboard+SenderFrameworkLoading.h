//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIStoryboard (SenderFrameworkLoading)

+ (UIStoryboard * _Nonnull)storyboardFromSenderFrameworkWithName:(NSString *)name;

@end