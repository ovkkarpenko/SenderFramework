//
// Created by Roman Serga on 27/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWAlertFacade.h"
#import "MWAlertPlayer.h"
#import "Owner.h"
#import "Settings.h"
#import "CoreDataFacade.h"

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }
#endif

@interface MWAlertFacade()

@property (nonatomic, strong) MWAlertPlayer * player;

@end

@implementation MWAlertFacade
{
    NSDate * lastPerformAlertCallDate;
}

+ (instancetype)sharedInstance
{
    static MWAlertFacade * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_main_sync_safe(^{
            sharedInstance = [[MWAlertFacade alloc] init];
        });
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.player = [[MWAlertPlayer alloc] init];
        lastPerformAlertCallDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    return self;
}

- (void)performAlertOfType:(MWAlertType)soundType
{
    if ([SenderCore sharedCore].isInBackground)
        return;

    NSDate * currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:lastPerformAlertCallDate] < 1)
        return;

    lastPerformAlertCallDate = currentDate;

    if ([DBSettings.sounds boolValue])
        [self.player playSoundOfType:soundType];
    if ([DBSettings.notificationsFlash boolValue])
        [self.player flash];
    if ([DBSettings.notificationsVibration boolValue])
        [self.player vibrate];
}

- (void)startVibration
{
    [self.player startVibrationWithDuration:3];
}

- (void)stopVibration
{
    [self.player stopVibration];
}


@end