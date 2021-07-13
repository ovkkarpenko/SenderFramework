//
//  UIView+ResizeAnimated.h
//  UIViewAnimation
//
//  Created by Eugene Gilko on 4/20/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ResizeAnimated)

- (void)changeHeighOfView:(CGFloat)newSize
         andAnimationTime:(CGFloat)time;

- (void)changeWidthOfView:(CGFloat)newSize
         andAnimationTime:(CGFloat)time;

- (void)changeSizeOfView:(CGFloat)newHeight
                andWidth:(CGFloat)newWidth
        andAnimationTime:(CGFloat)time;

- (void)changeSizeOfViewWithRect:(CGRect)newRect
                andAnimationTime:(CGFloat)time
                      completion:(void (^ __nullable)(BOOL finished))completion;

- (void)moveViewLeftAndAnimationTime:(CGFloat)time;
- (void)moveViewLeftAndAnimationTime:(CGFloat)time completionHandler:(void(^)(void))completionHandler;
- (void)moveViewRightAndAnimationTime:(CGFloat)time;
- (void)moveViewRightAndAnimationTime:(CGFloat)time completionHandler:(void(^)(void))completionHandler;

@end
