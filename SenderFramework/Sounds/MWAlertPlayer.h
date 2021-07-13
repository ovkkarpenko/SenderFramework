//
//  MWAlertPlayer.h
//  Sender
//
//  Created by Eugene Gilko on 9/15/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MWAlertType) {
    MWAlertTypeMessage,
    MWAlertTypeMoney
};

@interface MWAlertPlayer : NSObject

- (void)playSoundOfType:(MWAlertType)soundType;
- (void)playSoundWithURL:(NSURL *)soundURL;

- (void)setSoundURL:(NSURL *)soundURL forSoundType:(MWAlertType)soundType;

/*
 * One .2 second flash
 */
- (void)flash;

/*
 * One vibration
 */
- (void)vibrate;

- (void)startVibrationWithDuration:(NSTimeInterval)duration;
- (void)stopVibration;

@end
