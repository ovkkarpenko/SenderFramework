//
//  UIView+MWSubviews.h
//  iPay
//
//  Created by Serg Cyclone on 12.09.12.
//  Copyright (c) 2012 Serg Cyclone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (MWSubviews)

- (void)mw_iterateSubviewsWithBlock:(void(^)(UIView *subview))block;
- (void)mw_removeAllSubviews;
- (void)mw_removeAllGestureRecognizers;
+ (UIView *)mw_findFirstResponder;
- (void)mw_printSubviews;
- (UIView *)mw_findFirstResponder;
- (void)mw_replaceWith:(UIView*)anotherView;

/*
 * Pins subview with constraints to top, bottom, left and right of superview
 */
- (void)mw_pinSubview:(UIView *)subview;

@end
