//
//  PBButtonInFormView.m
//  SENDER
//
//  Created by Eugene on 10/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBButtonInFormView.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import "ConsoleCaclulator.h"
#import "BitcoinManager.h"
#import "Owner.h"
#import "MainContainerModel.h"

@implementation PBButtonInFormView
@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;

    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 0);

    self.viewModel = submodel;
    [self setupButton];
    self.backgroundColor = [UIColor clearColor];
    if  (_doneButton) {
        [self addSubview:_doneButton];
    }
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
    if ([self.viewModel.state isEqualToString:@"disable"]) {
        self.userInteractionEnabled = NO;
    }
}

- (void)setupButton
{
    CGFloat cHeight = 55.0f;
    CGFloat cWidth = self.frame.size.width;
    if (self.viewModel.h.integerValue > 0)
        cHeight = [self.viewModel.h floatValue];

    if (self.viewModel.w.integerValue > 0)
        cWidth = [self.viewModel.w floatValue];
    
    CGRect bttRect = CGRectMake(0, 0, cWidth, cHeight);
    
    _doneButton = [[UIButton alloc] initWithFrame:bttRect];

    if (self.viewModel.bg)
    {
        NSString * firstBg = [self.viewModel.bg substringToIndex:1];
        if ([firstBg isEqualToString:@"#"])
        {
            _doneButton.backgroundColor = [PBConsoleConstants colorWithHexString:self.viewModel.bg];
        }
        else
        {
            NSString * imageURL = [self.viewModel.bg stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [_doneButton sd_setImageWithURL:[NSURL URLWithString:imageURL] forState:UIControlStateNormal];
        }
    }
    else
    {
        _doneButton.backgroundColor = [UIColor clearColor];
    }

    if (self.viewModel.title.length)
    {
        [_doneButton setTitle:self.viewModel.title forState:UIControlStateNormal];
    }
    else
    {
        [_doneButton setTitle:self.viewModel.val forState:UIControlStateNormal];
    }

    if (self.viewModel.color)
    {
        [_doneButton setTitleColor:[PBConsoleConstants colorWithHexString:self.viewModel.color]
                          forState:UIControlStateNormal];
    }
    else
    {
        [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    UIFont * buttonFont = [PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle
                                                              andSize:self.viewModel.fontSize];
    [_doneButton.titleLabel setFont:buttonFont];
    [_doneButton addTarget:self action:@selector(buttonPushedAction) forControlEvents:UIControlEventTouchUpInside];

    self.frame = _doneButton.frame;
    [PBConsoleConstants settingViewBorder:_doneButton andModel:self.viewModel];
}

- (void)buttonPushedAction
{
    [self setActive:NO];

    if (self.viewModel.action)
    {
        [super doAction:self.viewModel.action];
        
        if ([self.viewModel detectAction:self.viewModel.action] == RunRobots)
            [self confirmButtonAction];
    }
    else if (self.viewModel.actions)
    {
        for (NSDictionary * action in self.viewModel.actions) {
            [super doAction:action];
        }
    }
    else
    {
        [self confirmButtonAction];
    }
    
    [self removeBlockTimer];
}

- (void)removeBlockTimer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (self) [self setActive:YES];
    });
}

- (void)confirmButtonAction
{
    if (self.viewModel.name && self.viewModel.val)
    {
        NSDictionary * bttData = @{@"name": self.viewModel.name, @"val": self.viewModel.val};
        [self.delegate pushOnButton:self didFinishEnteringItem:bttData];
    }
}

- (void)setActive:(BOOL)active
{
    self.userInteractionEnabled = active;
    self.alpha = active ? 1 : 0.2f;

}

@end
