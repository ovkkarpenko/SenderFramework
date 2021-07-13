//
// Created by Roman Serga on 27/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWAlertPlayer.h"

@interface MWAlertFacade : NSObject

+ (instancetype)sharedInstance;

/*
 * Plays sound of specified type (if sound is enabled) along with vibration and flash (if enabled).
 * Alerts not more often than 1 second
 */
- (void)performAlertOfType:(MWAlertType)soundType;

/*
 * Starts vibrating for 3 seconds.
 */
- (void)startVibration;

/*
 * Stops vibration
 */
- (void)stopVibration;

@end