//
//  RecordAudioView.m
//  SENDER
//
//  Created by Eugene on 11/3/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "RecordAudioView.h"
#import "SenderNotifications.h"
#import "PBConsoleConstants.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "Message.h"
#import "AVFoundation/AVAudioSession.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import <KAProgressLabel/KAProgressLabel.h>

const NSTimeInterval maxRecordTime = 29.5;
const NSTimeInterval minRecordTime = 1.0;

@implementation RecordAudioView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"RecordAudioView" owner:nil options:nil][0];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SCREEN_WIDTH, self.frame.size.height);
        self.isSetUp = NO;
        [self layoutIfNeeded];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioRecorderStoppedRecordingNotification:)
                                                     name:AudioRecorderDidStopRecording
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioRecorderStoppedPlayingNotification:)
                                                     name:AudioRecorderDidStopPlaying
                                                   object:nil];
    }
    return self;
}

- (void)audioRecorderStoppedRecordingNotification:(NSNotification *)notification
{
    recMode = NO;
    [self stopRepeatTimer];
}

- (void)audioRecorderStoppedPlayingNotification:(NSNotification *)notification
{
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"]
                     forState:UIControlStateNormal];
    [playTimer invalidate];
    playTimer = nil;
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f", durationOfRecordedFile];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUpView
{
    self.isSetUp = YES;
    timerCount = 0;
    [self.pLabel setBackBorderWidth: 4.0];
    [self.pLabel setFrontBorderWidth: 9.0];
    [self.pLabel setColorTable: @{
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelTrackColor):[UIColor clearColor],
                                  NSStringFromProgressLabelColorTableKey(ProgressLabelProgressColor):[[SenderCore sharedCore].stylePalette mainAccentColor]
                                  }];
    
    [self.startStopButton setTitleColor:[[SenderCore sharedCore].stylePalette mainAccentColor] forState:UIControlStateNormal];
    
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"] forState:UIControlStateNormal];
    
    recImage = [UIImage imageFromSenderFrameworkNamed:@"hold&talk_press"];
    stopImage = [UIImage imageFromSenderFrameworkNamed:@"hold&talk_normal"];
    [self changeRecBgImage:NO];
    [self setSendAudioButtonsVisible:NO];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, 1.0f);
    topBorder.backgroundColor = [[[SenderCore sharedCore].stylePalette mainAccentColor]colorWithAlphaComponent:0.2].CGColor;
    [self.layer addSublayer:topBorder];

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted)
            {
                self.noInputAvailiableView.hidden = NO;
                self.noInputAvailiableLabel.text = SenderFrameworkLocalizedString(@"error_mic_not_available", nil);
                self.noInputAvailiableLabel.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
                [self.goToSettingsButton setTitle:SenderFrameworkLocalizedString(@"error_mic_not_available_go_to_settings", nil) forState:UIControlStateNormal];
                [self.goToSettingsButton setTitleColor:[[SenderCore sharedCore].stylePalette mainAccentColor] forState:UIControlStateNormal];
            }
            else
            {
                self.noInputAvailiableView.hidden = YES;
            }
        });
    }];
}

-(IBAction)goToSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)updateCount
{
    timerCount += 0.015;
    if (timerCount * maxRecordTime >= minRecordTime) [self reEnableReccord];
    [self.pLabel setProgress:timerCount];
}

- (IBAction)sendRecordToServer:(id)sender
{
    [self changeRecBgImage:NO];
    [self setSendAudioButtonsVisible:NO];
    timerCount = 0;
    [self.pLabel setProgress:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL res = [[AudioRecorder sharedInstance]  convertToMp3];
        if (res)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate recordAudioViewDidRecordedTrack:[[AudioRecorder sharedInstance] getFileData]];
            });
        }
    });
}

- (IBAction)cancelRecord:(id)sender
{
    [self stopPlaying];
    timerCount = 0;
    [self.pLabel setProgress:0];

    [self changeRecBgImage:NO];
    [self setSendAudioButtonsVisible:NO];
}

- (IBAction)startRecordAudio:(id)sender
{
    if (!recMode) {
        recMode = YES;
    }
    else { recMode = NO; [self stopRecording]; return;}
    
    timerCount = 0;
    self.startStopButton.enabled = NO;
    [self.pLabel setProgress:0];
    self.sendButton.hidden = YES;
    self.playButton.hidden = YES;
    
    [[AudioRecorder sharedInstance] startRecord];
    [self changeRecBgImage:YES];
    
    repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(updateCount)
                                               userInfo:nil
                                                repeats:YES];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:29.5
                                                 target:self
                                               selector:@selector(stopRecording)
                                               userInfo:nil
                                                repeats:NO];
}

- (void)reEnableReccord
{
    self.startStopButton.enabled = YES;
    [self.startStopButton setTitle:SenderFrameworkLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
}

- (void)stopRepeatTimer
{
    [repeatTimer invalidate];
    repeatTimer = nil;
    [mainTimer invalidate];
    mainTimer =  nil;
    durationOfRecordedFile = [[AudioRecorder sharedInstance] getFileDuration];
    [self changeRecBgImage:NO];
    [self.startStopButton setTitle:SenderFrameworkLocalizedString(@"click_and_talk_ios", nil) forState:UIControlStateNormal];
    self.startStopButton.enabled = YES;

    if (durationOfRecordedFile < 0.01) {
        [self.pLabel setProgress:0];
        [self setSendAudioButtonsVisible:NO];
        return;
    }

    [self setSendAudioButtonsVisible:YES];
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f",durationOfRecordedFile];
    MWSenderFileManager.shared.lastRecorderAudioDuration = [NSString stringWithFormat:@"%f",durationOfRecordedFile];
}

- (IBAction)playRecordedAudio:(id)sender
{
    if ([[AudioRecorder sharedInstance]  playerStatus])
        [self stopPlaying];
    else
        [self startPlaying];
}

- (void)stopPlaying
{
    [[AudioRecorder sharedInstance] stopPlay];
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"]
                     forState:UIControlStateNormal];
    [playTimer invalidate];
    playTimer = nil;
}

- (void)startPlaying
{
    if ([[AudioRecorder sharedInstance]  playWithDelegate:self])
    {
        [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"pause"]
                         forState:UIControlStateNormal];

        playTimer = [NSTimer
                scheduledTimerWithTimeInterval:0.1
                                        target:self selector:@selector(timerFired:)
                                      userInfo:nil repeats:YES];
    }
}

- (void)timerFired:(NSTimer*)timer
{
    [self updateDisplay];
}

- (void)updateDisplay
{
    NSTimeInterval currentTime = [[AudioRecorder sharedInstance] currentTime:self];
    if (currentTime < 0) {return;}
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f", currentTime];
}

- (IBAction)stopRecording
{
    [[AudioRecorder sharedInstance] stopRecord];
    [self stopRepeatTimer];
}

- (void)changeRecBgImage:(BOOL)mode
{
    recBgImageView.image = mode ? recImage : stopImage;
}

- (void)setSendAudioButtonsVisible:(BOOL)visible
{
    self.pLabel.hidden = visible;
    self.startStopButton.hidden = visible;
    recBgImageView.hidden = visible;
    
    durationOfRecordedFileLabel.hidden = !visible;
    self.sendButton.hidden = !visible;
    self.playButton.hidden = !visible;
    self.cancelButton.hidden = !visible;
    playBgImageView.hidden = !visible;
    self.playButton.hidden = !visible;
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [playTimer invalidate];
    playTimer = nil;
    [self.playButton setImage:[UIImage imageFromSenderFrameworkNamed:@"play"]
                     forState:UIControlStateNormal];
    durationOfRecordedFileLabel.text = [NSString stringWithFormat:@"%.02f", durationOfRecordedFile];
}

@end
