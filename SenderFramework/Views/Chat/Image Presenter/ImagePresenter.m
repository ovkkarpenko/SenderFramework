//
// Created by Roman Serga on 24/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "ImagePresenter.h"
#import "PBConsoleConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+Resize.h"
#import "UIImage+animatedGIF.h"
#import "UIView+ResizeAnimated.h"
#import "UIAlertView+CompletionHandler.h"

@interface ImagePresenter ()
{
    CGRect childImageStoredRect;
    CGFloat lastRotation;
    CGRect frameAfterTransform;
}

@property(nonatomic, strong) UIImageView * imageView;
@property(nonatomic, strong) UITapGestureRecognizer * tapRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer * doubleTapRecognizer;
@property(nonatomic, strong) UIRotationGestureRecognizer * rotationRecognizer;

@end

@implementation ImagePresenter

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        [self createAndConfigureScrollView];
        [self createAndConfigureWindow];
        [self createAndConfigureImageView];

        [self.presentationWindow addSubview:self.zoomingScrollView];
        [self.zoomingScrollView addSubview:self.imageView];

        [self createAndConfigureRecognizers];

        [self.zoomingScrollView addGestureRecognizer:self.doubleTapRecognizer];
        [self.zoomingScrollView addGestureRecognizer:self.rotationRecognizer];
        [self.presentationWindow addGestureRecognizer:self.tapRecognizer];
    }
    return self;
}

-(void)createAndConfigureScrollView
{
    self.zoomingScrollView = [[UIScrollView alloc]init];
    self.zoomingScrollView.scrollsToTop = NO;
    self.zoomingScrollView.maximumZoomScale = 6.0;
    self.zoomingScrollView.showsHorizontalScrollIndicator = NO;
    self.zoomingScrollView.showsVerticalScrollIndicator = NO;
    self.zoomingScrollView.delegate = self;
    self.zoomingScrollView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    self.zoomingScrollView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)createAndConfigureWindow
{
    self.presentationWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0.0f, 0.0f, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.presentationWindow.backgroundColor = [UIColor clearColor];
}

-(void)createAndConfigureImageView
{
    self.imageView = [[UIImageView alloc]init];
    self.imageView.backgroundColor = [UIColor whiteColor];
}

-(void)createAndConfigureRecognizers
{
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    self.doubleTapRecognizer.numberOfTouchesRequired = 1;

    self.rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];

    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissWindowWithImage)];
    self.tapRecognizer.numberOfTapsRequired = 1;
    self.tapRecognizer.numberOfTouchesRequired = 1;
    self.tapRecognizer.delaysTouchesEnded = YES;
    [self.tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
}

-(void)presentWindowWithImage:(UIImage *)image withTransformFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame
{
    childImageStoredRect = fromFrame;
    frameAfterTransform = toFrame;
    self.zoomingScrollView.frame = childImageStoredRect;
    [self finishShowingImage:image];
}

- (void)showPhotoLibraryNotAvailableError
{
    NSString * title = SenderFrameworkLocalizedString(@"error_photo_library_not_available", nil);
    NSString * goToSettings = SenderFrameworkLocalizedString(@"error_photo_library_not_available_go_to_settings", nil);

    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:title
                                                          message:nil
                                                         delegate:nil
                                                cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                otherButtonTitles: goToSettings, nil];
    [myAlertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != alertView.cancelButtonIndex)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
}

- (void)finishShowingImage:(UIImage *)image
{
    if (image)
    {
        [image transformForOrientation:frameAfterTransform.size];
        lastRotation = 0.0f;

        self.imageView.image = image;
        self.imageView.transform = CGAffineTransformIdentity;

        NSArray *windows = [[UIApplication sharedApplication] windows];
        UIWindow *lastWindow = (UIWindow *)[windows lastObject];
        self.presentationWindow.windowLevel = lastWindow.windowLevel + 1;

        [self.zoomingScrollView changeSizeOfViewWithRect:frameAfterTransform
                                        andAnimationTime:0.3
                                              completion:^(BOOL finished) {
            self.isPresentingImage = YES;
        }];

        CGFloat newHeight = self.zoomingScrollView.frame.size.width / image.size.width * image.size.height;
        CGFloat newY = (self.zoomingScrollView.frame.size.height - newHeight) / 2;
        self.imageView.frame = CGRectMake(0,
                                          newY,
                                          self.zoomingScrollView.frame.size.width,
                                          newHeight);
        self.zoomingScrollView.contentSize = self.imageView.frame.size;

        [self.presentationWindow makeKeyAndVisible];
    }
}

- (void)rotate:(UIRotationGestureRecognizer*)recognizer
{
    if([recognizer state] == UIGestureRecognizerStateEnded)
    {
        lastRotation = 0.0f;
        return;
    }

    CGFloat rotation = 0.0f - (lastRotation - recognizer.rotation);

    self.imageView.transform = CGAffineTransformRotate(self.imageView.transform,rotation);
    lastRotation = recognizer.rotation;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.zoomingScrollView.zoomScale > self.zoomingScrollView.minimumZoomScale)
        [self.zoomingScrollView setZoomScale:self.zoomingScrollView.minimumZoomScale animated:YES];
    else
        [self.zoomingScrollView setZoomScale:3.0f animated:YES];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIImage * image = self.imageView.image;
    CGFloat newHeight = self.zoomingScrollView.contentSize.width / image.size.width * image.size.height;
    CGFloat newY = self.zoomingScrollView.frame.size.height - newHeight;
    newY = newY > 0 ? newY / 2 : 0;
    self.imageView.frame = CGRectMake(0,
                                      newY,
                                      self.zoomingScrollView.contentSize.width,
                                      self.zoomingScrollView.contentSize.height);
}

-(void)dismissWindowWithImage
{
    [self.zoomingScrollView changeSizeOfViewWithRect:childImageStoredRect
                                    andAnimationTime:0.2
                                          completion:^(BOOL finished) {
        self.presentationWindow.hidden = YES;
        self.isPresentingImage = NO;
        if ([self.delegate respondsToSelector:@selector(imagePresenter:didDismissed:)])
            [self.delegate imagePresenter:self didDismissed:YES];
    }];
}

@end
