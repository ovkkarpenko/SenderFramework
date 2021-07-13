//
// Created by Roman Serga on 7/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWKeyboardListener.h"

static MWKeyboardListener *sharedInstance;

@interface MWKeyboardListener()

@property (nonatomic, readwrite) BOOL isKeyboardVisible;

@end

@implementation MWKeyboardListener

+ (MWKeyboardListener *)sharedListener
{
    return sharedInstance;
}

+ (void)load
{
    @autoreleasepool {
        sharedInstance = [[self alloc] init];
    }
}

- (void)didShow
{
    self.isKeyboardVisible = YES;
}

- (void)didHide
{
    self.isKeyboardVisible = NO;
}

- (id)init
{
    if ((self = [super init])) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShow) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

@end