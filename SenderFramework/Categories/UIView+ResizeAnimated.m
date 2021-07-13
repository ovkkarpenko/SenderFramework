//
//  UIView+ResizeAnimated.m
//  UIViewAnimation
//
//  Created by Eugene Gilko on 4/20/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import "UIView+ResizeAnimated.h"

@implementation UIView (ResizeAnimated)

- (void)changeHeighOfView:(CGFloat)newSize
         andAnimationTime:(CGFloat)time
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        CGRect theBounds = self.bounds;
        CGPoint theCenter = self.center;
        float increment = newSize - theBounds.size.height;
        theBounds.size.height = newSize;
        theCenter.y += increment/2;
        self.bounds = theBounds;
        self.center = theCenter;
    }];
}

- (void)changeWidthOfView:(CGFloat)newSize
         andAnimationTime:(CGFloat)time
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        CGRect theBounds = self.bounds;
        CGPoint theCenter = self.center;
        float increment = newSize - theBounds.size.width;
        theBounds.size.width = newSize;
        theCenter.x += increment/2;
        self.bounds = theBounds;
        self.center = theCenter;
    }];
}

- (void)changeSizeOfView:(CGFloat)newHeight
                andWidth:(CGFloat)newWidth
        andAnimationTime:(CGFloat)time
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        CGRect theBounds = self.bounds;
        CGPoint theCenter = self.center;
        float incrementY = newHeight - theBounds.size.height;
        float incrementX = newWidth - theBounds.size.width;
        theBounds.size.height = newHeight;
        theBounds.size.width = newWidth;
        theCenter.x += incrementX/2;
        theCenter.y += incrementY/2;
        self.bounds = theBounds;
        self.center = theCenter;
    }];
}

- (void)changeSizeOfViewWithRect:(CGRect)newRect
                andAnimationTime:(CGFloat)time
        completion:(void (^ __nullable)(BOOL finished))completion
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        self.frame = newRect;
    } completion: completion];
}

- (void)moveViewLeftAndAnimationTime:(CGFloat)time
{
    [self moveViewLeftAndAnimationTime:time completionHandler:nil];
}

- (void)moveViewLeftAndAnimationTime:(CGFloat)time completionHandler:(void(^)(void))completionHandler
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        CGRect theBounds = self.bounds;
        CGPoint theCenter = self.center;
        float incrementX = theBounds.size.width;
        theCenter.x -= incrementX;
        self.bounds = theBounds;
        self.center = theCenter;
    } completion:^(BOOL finished) {
        if (finished && completionHandler)
            completionHandler();
    }];
}

- (void)moveViewRightAndAnimationTime:(CGFloat)time
{
    [self moveViewRightAndAnimationTime:time completionHandler:nil];
}

- (void)moveViewRightAndAnimationTime:(CGFloat)time completionHandler:(void(^)(void))completionHandler
{
    self.layer.needsDisplayOnBoundsChange = YES;
    self.contentMode = UIViewContentModeRedraw;
    [UIView animateWithDuration:time animations:^{
        CGRect theBounds = self.bounds;
        CGPoint theCenter = self.center;
        float incrementX = theBounds.size.width;
        theCenter.x += incrementX;
        self.bounds = theBounds;
        self.center = theCenter;
    } completion:^(BOOL finished) {
        if (finished && completionHandler)
            completionHandler();
    }];
}

@end
