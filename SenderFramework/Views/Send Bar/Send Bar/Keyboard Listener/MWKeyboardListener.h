//
// Created by Roman Serga on 7/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Taken from https://stackoverflow.com/a/1492436
 */

@interface MWKeyboardListener : NSObject

+ (MWKeyboardListener *)sharedListener;

@property (nonatomic, readonly) BOOL isKeyboardVisible;

@end