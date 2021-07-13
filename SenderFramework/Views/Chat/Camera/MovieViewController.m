//
//  MovieViewController.m
//  SENDER
//
//  Created by Eugene on 12/8/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MovieViewController.h"
#import "PBConsoleConstants.h"
#import "UIView+MWSubviews.h"

@interface MovieViewController ()

@property (nonatomic, strong) NSURL * urlVideo;

@end

@implementation MovieViewController

- (id)initWithURL:(NSURL *)urlV
{
    self = [super init];
    if (self && (urlV != nil))
    {
        self.urlVideo = urlV;

        self.videoController = [[MPMoviePlayerController alloc] init];

        self.videoController.shouldAutoplay = YES;
        [self.videoController setContentURL:self.urlVideo];

        self.videoController.scalingMode = MPMovieScalingModeAspectFit;
        self.videoController.fullscreen = YES;

        [self.videoController setControlStyle:MPMovieControlStyleFullscreen];

        [self.view addSubview:self.videoController.view];

        self.videoController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view mw_pinSubview:self.videoController.view];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(myMovieFinishedCallback)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.videoController];

        [self.videoController prepareToPlay];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setVideoController:(MPMoviePlayerController *)videoController
{
    if (_videoController)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                      object:_videoController];
    }
    _videoController = videoController;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChangeNotification:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_videoController];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChangeNotification:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:_videoController];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerReadyForDisplayDidChangeNotification:)
                                                 name:MPMoviePlayerReadyForDisplayDidChangeNotification
                                               object:_videoController];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerDidFinishNotification:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:_videoController];
}

- (void)moviePlayerDidFinishNotification:(NSNotification *)notification
{
    [self backButtonAction];
}

- (void)moviePlayerReadyForDisplayDidChangeNotification:(NSNotification *)notification
{
    [self showVideo];
}

- (void)showVideo
{
    if (self.videoController.readyForDisplay &&
        (self.videoController.loadState == MPMovieLoadStatePlayable ||
        self.videoController.loadState == MPMovieLoadStatePlaythroughOK))
        [self.videoController play];
}

- (void)moviePlayerPlaybackStateDidChangeNotification:(NSNotification *)notification
{
    /*
     * If MPMoviePlayerController hasn't loaded video,
     * it will change its playbackState to MPMoviePlaybackStateStopped.
     * We shouldn't dismiss video player in suck situations.
     */
    if (!self.videoController.readyForDisplay)
        return;

    switch (self.videoController.playbackState) {
        case MPMoviePlaybackStateStopped:
            [self backButtonAction];
            break;
        case MPMoviePlaybackStatePlaying:
            break;
        case MPMoviePlaybackStatePaused:
            break;
        default:
            break;
    }
}

- (void)moviePlayerLoadStateDidChangeNotification:(NSNotification *)notification
{
    [self showVideo];
}

- (void)myMovieFinishedCallback
{
    self.videoController.initialPlaybackTime = 0;
}

- (void)backButtonAction
{
    [self.videoController stop];
    if ([self.delegate respondsToSelector:@selector(movieViewControllerDidFinish:)])
        [self.delegate movieViewControllerDidFinish:self];
}

@end
