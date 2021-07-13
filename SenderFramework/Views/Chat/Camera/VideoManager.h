//
//  VideoManager.h
//  SENDER
//
//  Created by Eugene on 12/11/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraManager.h"

@class VideoManager;

@protocol VideoManagerDelegate <NSObject>

- (void)         videoManager:(VideoManager *)videoManager
didFinishPickingVideoWithData:(NSData *)data
                     duration:(NSTimeInterval)duration;
- (void)videoManager:(VideoManager *)videoManager didFinishWithError:(NSError *)error;

@end

@interface VideoManager : NSObject  <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) id<VideoManagerDelegate> delegate;

- (id)initWithParentController:(UIViewController *)controller;
- (void)showCamera;

@end
