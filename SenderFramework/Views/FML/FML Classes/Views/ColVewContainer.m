//
//  ColVewContainer.m
//  SENDER
//
//  Created by Eugene on 1/11/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ColVewContainer.h"
#import "MainContainerModel.h"

@implementation ColVewContainer
@synthesize viewModel;

- (id)initWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    return [super initWithRect:mainRect andModel:submodel];
}

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
}

- (void)doAction
{
    if (self.viewModel.action)
    {
        [super doAction:self.viewModel.action];
    }
    else if (self.viewModel.actions)
    {
        for (NSDictionary * action_ in self.viewModel.actions) {
            [super doAction:action_];
        }
    }
}

- (void)correctMarginAndPaddingSize:(PBSubviewFacade *)innerView
{
    CGRect newViewRect = self.frame;
    
    if (self.viewModel.h) {
        newViewRect.size.height = (int)[self.viewModel.h integerValue];
        CGRect contentRect = self.contentView.frame;
        contentRect.size.height = [self.viewModel correctHeight];
        self.contentView.frame = contentRect;
        innerView.frame = contentRect;
        [self correctPaddingView];
    }
    else {
        float maxSize = 0;
        
        if (innerView) {
            CGRect contentRect = self.contentView.frame;
            contentRect.size.height = innerView.frame.size.height;
            self.contentView.frame = contentRect;
            maxSize = contentRect.size.height;
        }
        
        if (self.viewModel.viewHavePadding) {
            [self correctPaddingView];
            maxSize = self.paddingView.frame.size.height;
        }
        
        if (self.viewModel.viewHaveMargins) {
            maxSize += [self newMaxHeigh:maxSize];
        }
        newViewRect.size.height = maxSize;
    }
    
    self.frame = newViewRect;
}

- (float)newMaxHeigh:(float)oldHeight
{
    oldHeight += ((int)[self.viewModel.mg[0] integerValue] + (int)[self.viewModel.mg[2] integerValue]);
    return oldHeight;
}

- (void)correctPaddingView
{
    CGRect paddingRect = self.paddingView.frame;
    paddingRect.size.height = self.contentView.frame.size.height;
    paddingRect.size.height += ((int)[self.viewModel.pd[0] integerValue] + (int)[self.viewModel.pd[2] integerValue]);
}

@end
