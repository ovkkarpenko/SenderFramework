//
//  RecordAudioView.h
//  SENDER
//
//  Created by Eugene on 11/3/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioRecorder.h"

@class KAProgressLabel;

@protocol RecordAudioViewDelegate <NSObject>

-(void)recordAudioViewDidRecordedTrack:(NSData*)data;

@end

@interface RecordAudioView : UIView <AVAudioPlayerDelegate>
{
    float timerCount;
    NSTimer * mainTimer;
    NSTimer * repeatTimer;
    NSTimer * playTimer;
    AudioRecorder * recorder;
    IBOutlet UIImageView * recBgImageView;
    IBOutlet UIImageView * playBgImageView;
    IBOutlet UILabel * durationOfRecordedFileLabel;
    UIImage * recImage;
    UIImage * stopImage;
    float durationOfRecordedFile;
    BOOL recMode;
}

@property (nonatomic, weak) id<RecordAudioViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton * startStopButton;
@property (nonatomic, strong) IBOutlet UIButton * sendButton;
@property (nonatomic, strong) IBOutlet UIButton * cancelButton;
@property (nonatomic, strong) IBOutlet UIButton * playButton;
@property (nonatomic, strong) IBOutlet UIVisualEffectView   * noInputAvailiableView;
@property (nonatomic, strong) IBOutlet UILabel   * noInputAvailiableLabel;
@property (nonatomic, strong) IBOutlet UIButton   * goToSettingsButton;

@property (nonatomic, weak) IBOutlet KAProgressLabel * pLabel;

@property (nonatomic) BOOL isSetUp;

- (void)setUpView;
- (IBAction)cancelRecord:(id)sender;

@end
