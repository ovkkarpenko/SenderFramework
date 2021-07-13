//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatTableViewCell+SelectedAccessory.h"

@implementation ChatTableViewCell (SelectedAccessory)

- (void)showSelectedAccessory
{
    UIView * background = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    background.backgroundColor = [UIColor clearColor];

    UIView * outerCircle = [[UIView alloc]initWithFrame:CGRectMake(5.0f, 5.0f, 34.0f, 34.0f)];
    background.backgroundColor = [UIColor clearColor];
    outerCircle.layer.borderWidth = 1.0f;
    outerCircle.layer.borderColor = [[SenderCore sharedCore].stylePalette mainAccentColor].CGColor;
    outerCircle.layer.cornerRadius = outerCircle.frame.size.height / 2;

    [background addSubview:outerCircle];

    UIView * innerCircle = [[UIView alloc]initWithFrame:CGRectMake(6.0f, 6.0f, 22.0f, 22.0f)];
    [outerCircle addSubview:innerCircle];
    innerCircle.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    innerCircle.layer.cornerRadius = innerCircle.frame.size.width / 2;

    [self setCustomAccessory:background];
}

- (void)showDeselectedAccessory
{
    UIView * background = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    background.backgroundColor = [UIColor clearColor];

    UIView * outerCircle = [[UIView alloc]initWithFrame:CGRectMake(5.0f, 5.0f, 34.0f, 34.0f)];
    background.backgroundColor = [UIColor clearColor];
    outerCircle.layer.borderWidth = 1.0f;
    outerCircle.layer.borderColor = [[SenderCore sharedCore].stylePalette mainAccentColor].CGColor;
    outerCircle.layer.cornerRadius = outerCircle.frame.size.height / 2;

    [background addSubview:outerCircle];

    [self setCustomAccessory:background];
}

@end