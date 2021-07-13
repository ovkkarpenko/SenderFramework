//
//  UIView+subviews.m
//  iPay
//
//  Created by Serg Cyclone on 12.09.12.
//  Copyright (c) 2012 Serg Cyclone. All rights reserved.
//

#import "UIView+MWSubviews.h"

@implementation UIView (MWSubviews)


-(void)mw_iterateSubviewsWithBlock:(void(^)(UIView *subview))block
{
	for (UIView *vs in [self subviews])
    {
		[vs mw_iterateSubviewsWithBlock:block];
		block(vs);
	}
}

-(void)mw_removeAllSubviews
{
	for (UIView *v in [self subviews])
		[v removeFromSuperview];
}

-(void)mw_removeAllGestureRecognizers
{
	for (id rec in [self gestureRecognizers])
		[self removeGestureRecognizer:rec];
}

- (UIView *)mw_findFirstResponder
{
    if (self.isFirstResponder)
    {
        return self;
    }
	
    for (UIView* subView in self.subviews)
    {
        UIView* firstResponder = [subView mw_findFirstResponder];
		
        if (firstResponder != nil)
        {
			return firstResponder;
        }
    }
	
    return nil;
}

+ (UIView*)mw_findFirstResponder
{
	return [[[UIApplication sharedApplication] keyWindow] mw_findFirstResponder];
}

void printSubviewsInternal(UIView *view, int placeholders, BOOL noSubitems)
{
	NSString* tmp = @"";
	for (int i = 0; i < placeholders; i++)
		tmp = [tmp stringByAppendingString:@" "];
	
	if (!noSubitems)
		for (UIView *v in [view subviews])
        {
			if ([v isKindOfClass:[UIControl class]])
				printSubviewsInternal(v, placeholders + 1, YES);
			else
				printSubviewsInternal(v, placeholders + 1, NO);
		}
}

-(void)mw_replaceWith:(UIView*)anotherView
{
	anotherView.frame = self.frame;
	[self.superview insertSubview:anotherView aboveSubview:self];
	[self removeFromSuperview];
}

void printSubviews(UIView *view)
{
	printSubviewsInternal(view, 0, NO);
}

-(void)mw_printSubviews
{
	printSubviewsInternal(self, 0, NO);
}

- (void)mw_pinSubview:(UIView *)subview
{
	if (subview.superview != self)
		return;

	NSLayoutAttribute attributes[] = {NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeBottom};
	for (int i = 0; i < 4; i++)
	{
		NSLayoutAttribute attribute = attributes[i];
		NSLayoutConstraint  * constraint = [NSLayoutConstraint constraintWithItem:self
																		attribute:attribute
																		relatedBy:NSLayoutRelationEqual
																		   toItem:subview
																		attribute:attribute
																	   multiplier:1.0f
																		 constant:0.0f];
		[self addConstraint:constraint];
	}
}


@end
