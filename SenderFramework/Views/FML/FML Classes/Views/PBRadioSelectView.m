//
//  PBRadioSelectView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBRadioSelectView.h"
#import "PBCheckBoxModel.h"
#import "BitcoinUtils.h"
#import "MainContainerModel.h"

@interface PBRadioSelectView()
{
    __strong NSArray * checkBoxViewsArray;
}

@end

@implementation PBRadioSelectView

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 42.0);
    self.backgroundColor = [UIColor clearColor];

    NSMutableArray * tempViewsArray = [[NSMutableArray alloc] init];
    
    int k = 0;
    float originY = 0;
    
    if (self.viewModel.vars.count) {
        
        for (NSDictionary * boxData in self.viewModel.vars) {
            
            PBCheckBoxModel * boxModel = [[PBCheckBoxModel alloc] initWithData:boxData];
            boxModel.isRadioButton = YES;
            boxModel.cellIndificator = k;

            PBRadioButtonView * boxView = [[PBRadioButtonView alloc] initWithModel:boxModel
                                                                           andRect:CGRectMake(0, originY, mainRect.size.width, 35.0)];
            [tempViewsArray addObject:boxView];
            boxView.delegate = self;
            originY += boxView.frame.size.height;
            
            if ([self.viewModel.val isEqualToString:boxModel.value]) {
                [boxView changeViewMode:YES];
            }
            
            [self addSubview:boxView];
            k++;
        }
    }

    checkBoxViewsArray = tempViewsArray;
    CGRect rect = self.frame;
    rect.size.height = originY + 10.0f;
    self.frame = rect;
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
}

- (void)pushOnRadio:(PBRadioButtonView *)controller didFinishEnteringItem:(PBCheckBoxModel *)model
{
    for (PBRadioButtonView * checkBox in checkBoxViewsArray)
    {
        if (checkBox.boxModel.cellIndificator == model.cellIndificator)
        {
            [checkBox changeViewMode:YES];
            self.viewModel.val = model.value;
            model.selected = YES;
        
        }
        else
        {
            [checkBox changeViewMode:NO];
            model.selected = NO;
        }
    }

    if (model.action)
    {
        [super doAction:model.action];
    }
    else if (model.actions)
    {
        for (NSDictionary * action in model.actions)
        {
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
}

@end
