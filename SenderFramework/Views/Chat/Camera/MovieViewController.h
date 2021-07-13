//
//  MovieViewController.h
//  SENDER
//
//  Created by Eugene on 12/8/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@class MovieViewController;

@protocol MovieViewControllerDelegate <NSObject>

- (void)movieViewControllerDidFinish:(MovieViewController *)movieViewController;

@end

@interface MovieViewController : UIViewController

@property (strong, nonatomic) MPMoviePlayerController *videoController;

@property (nonatomic, weak) id<MovieViewControllerDelegate> delegate;

- (instancetype _Nonnull)initWithURL:(NSURL *)urlV;

@end
