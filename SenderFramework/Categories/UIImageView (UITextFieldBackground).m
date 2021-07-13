//
//  UITextField+Background.m
//  Privat24-ios
//
//  Created by Dima Yarmolchuk on 20.06.13.
//  Copyright (c) 2013 Middleware Inc. All rights reserved.
//

#import "UIImageView (UITextFieldBackground).h"

@implementation UIImageView (UITextFieldBackground)

- (void)setStretchablesenderFrameworkImageNamed:(NSString *)name
{    
    UIImage * tfBackgroundImage = [UIImage imageFromSenderFrameworkNamed:name];
    tfBackgroundImage = [tfBackgroundImage stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0];
    [self setImage:tfBackgroundImage];
}

- (void)setStretchableBgImage:(NSString *)name
{
    UIImage * tfBackgroundImage = [UIImage imageFromSenderFrameworkNamed:name];
    tfBackgroundImage = [tfBackgroundImage stretchableImageWithLeftCapWidth:5.0 topCapHeight:10.0];
    [self setImage:tfBackgroundImage];
}

- (void)setStretchableBalon:(NSString *)name
{
    UIImage * tfBackgroundImage = [[UIImage imageFromSenderFrameworkNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 25, 20)];
    [self setImage:tfBackgroundImage];
}

- (void)setStretchableOwnerBalon:(NSString *)name
{
    UIImage * tfBackgroundImage = [[UIImage imageFromSenderFrameworkNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20,20, 20)];
    [self setImage:tfBackgroundImage];
}

- (void)setStretchableGuestBalon:(NSString *)name
{
    UIImage * tfBackgroundImage = [[UIImage imageFromSenderFrameworkNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20)];
    [self setImage:tfBackgroundImage];
}

// { .left = 50, .right = 50, .top = 10, .bottom = 10 };

- (void)setUserPicture:(NSString *)theURL
{
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:theURL]];
    UIImage * tfBackgroundImage = [UIImage imageWithData:imageData];
    self.layer.cornerRadius = 8.0;
    self.clipsToBounds = YES;
    [self setImage:tfBackgroundImage];
}

- (void)setFadeingDownBg:(NSString *)name
{
    //top, left, bottom, right;
    UIImage * tfBackgroundImage = [[UIImage imageFromSenderFrameworkNamed:name] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 40, 0)];
    [self setImage:tfBackgroundImage];
}



@end
