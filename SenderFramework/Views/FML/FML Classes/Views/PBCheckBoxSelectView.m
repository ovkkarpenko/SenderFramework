//
//  PBCheckBoxSelectView.m
//  SENDER
//
//  Created by Eugene on 11/20/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBCheckBoxSelectView.h"
#import "PBCheckBoxModel.h"
#import "MainContainerModel.h"

@implementation PBCheckBoxSelectView

@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 42.0);
    self.backgroundColor = [UIColor clearColor];
    
    float originY = 0;
    
    NSDictionary * boxData = @{@"t": self.viewModel.title};
    
    PBCheckBoxModel * boxModel = [[PBCheckBoxModel alloc] initWithData:boxData];
    boxModel.isRadioButton = NO;
    
    PBCheckBoxView * boxView = [[PBCheckBoxView alloc] initWithModel:boxModel andRect:CGRectMake(0.0f, originY, mainRect.size.width, 32.0f)];
    boxView.delegate = self;
    originY += boxView.frame.size.height;

    if ([self.viewModel.val boolValue]) {
        boxModel.selected = YES;
        [self changeView:boxView andFixModelValue:boxModel];
    }
    else {
        boxModel.selected = NO;
        [self changeView:boxView andFixModelValue:boxModel];
    }
    
    [self addSubview:boxView];
    CGRect rect = self.frame;
    rect.size.height = originY + 10.0f;
    self.frame = rect;
}

- (void)pushOnCheckBox:(PBCheckBoxView *)controller didFinishEnteringItem:(PBCheckBoxModel *)model
{
    model.selected = !model.selected;
    
    if (model.action)
    {
        [super doAction:model.action];
    }
    else if (model.actions)
    {
        for (NSDictionary * action in model.actions) {
            [super doAction:action];
        }
    }

    if (self.viewModel.action)
    {
        [super doAction:self.viewModel.action];
    }
    else if (self.viewModel.actions)
    {
        for (NSDictionary * action in self.viewModel.actions)
        {
            [super doAction:action];
        }
    }

    [self changeView:controller andFixModelValue:model];
}

- (void)changeView:(PBCheckBoxView *)controller andFixModelValue:(PBCheckBoxModel *)model
{
    if (model.selected) {
        self.viewModel.val = @"true";
    }
    else {
        self.viewModel.val = @"false";
    }
    [controller changeViewMode:model.selected];
}

@end
