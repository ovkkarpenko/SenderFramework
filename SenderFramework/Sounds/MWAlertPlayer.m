//
//  AudioPalyer.m
//  Sender
//
//  Created by Eugene Gilko on 9/15/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MWAlertPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ServerFacade.h"
#import "Settings.h"
#import "Owner.h"

@interface MWAlertPlayer ()
{
    NSTimer * vibrationTimer;
    NSMutableDictionary * soundsDictionary;
}

void soundPlayCompletion(SystemSoundID soundID, void *clientData);
NSString * stringFromSenderSoundType(MWAlertType soundType);

@end

@implementation MWAlertPlayer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        soundsDictionary = [NSMutableDictionary dictionary];
        [self setDefaultSoundsPreset];
    }
    return self;
}

- (void)setDefaultSoundsPreset
{
    NSURL * clickSoundURL = [SENDER_FRAMEWORK_BUNDLE URLForResource: @"sw" withExtension: @"caf"];
    NSURL * moneySoundURL = [SENDER_FRAMEWORK_BUNDLE URLForResource: @"tk" withExtension: @"caf"];
    [self setSoundURL:clickSoundURL forSoundType:MWAlertTypeMessage];
    [self setSoundURL:moneySoundURL forSoundType:MWAlertTypeMoney];
}

- (void)setSoundURL:(NSURL *)soundURL forSoundType:(MWAlertType)soundType
{
    NSString * key = stringFromSenderSoundType(soundType);
    soundsDictionary[key] = soundURL;
}

- (NSURL *)soundURLForType:(MWAlertType)soundType
{
    NSString * key = stringFromSenderSoundType(soundType);
    return soundsDictionary[key];
}

NSString * stringFromSenderSoundType(MWAlertType soundType)
{
    switch (soundType) {
        case MWAlertTypeMessage:
            return @"MWAlertTypeMessage";
        case MWAlertTypeMoney:
            return @"MWAlertTypeMoney";
    }
}

- (void)playSoundOfType:(MWAlertType)soundType
{
    NSURL * soundURL = [self soundURLForType:soundType];
    [self playSoundWithURL:soundURL];
}

- (void)playSoundWithURL:(NSURL *)soundURL
{
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID (CFBridgingRetain(soundURL), &soundID);
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundPlayCompletion, NULL);
    AudioServicesPlayAlertSound(soundID);
}

void soundPlayCompletion(SystemSoundID soundID, void *clientData)
{
    AudioServicesDisposeSystemSoundID(soundID);
}

- (void)vibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)startVibrationWithDuration:(NSTimeInterval)duration
{
    if (!vibrationTimer)
    {
        vibrationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(vibrate) userInfo:nil repeats:YES];
        [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(stopVibration) userInfo:nil repeats:NO];
    }
}

- (void)stopVibration
{
    if (vibrationTimer)
    {
        [vibrationTimer invalidate];
        vibrationTimer = nil;
    }
}

- (void)flash
{
    if ([[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] hasTorch] &&
             [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo].torchMode == AVCaptureTorchModeOff)
    {
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] lockForConfiguration:nil];
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] setTorchMode:AVCaptureTorchModeOn];
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] unlockForConfiguration];
        
        [self performSelector:@selector(flashOff) withObject:nil afterDelay:0.2];
    }		
}

- (void)flashOff
{
    if ([[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] hasTorch] &&
        [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo].torchMode == AVCaptureTorchModeOn)
    {
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] lockForConfiguration:nil];
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] setTorchMode:AVCaptureTorchModeOff];
        [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] unlockForConfiguration];
    }
}

@end
