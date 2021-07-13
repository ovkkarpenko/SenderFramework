//
// Created by Roman Serga on 24/6/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImagePresenter;

@protocol ImagePresenterDelegate <NSObject>

-(void)imagePresenter:(ImagePresenter *)presenter didDismissed:(BOOL)unused;

@end

@interface ImagePresenter : NSObject <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView * zoomingScrollView;
@property (nonatomic, strong) UIWindow * presentationWindow;

@property (nonatomic, weak) id<ImagePresenterDelegate> delegate;
@property (nonatomic) BOOL isPresentingImage;

-(void)presentWindowWithImage:(UIImage *)image withTransformFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame;
-(void)dismissWindowWithImage;

@end