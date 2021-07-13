//
//  PBPopUpSelector.h
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainContainerModel.h"

@class PBPopUpSelector;

@protocol PBPopUpSelectorDelegate <NSObject>

- (void)popUpSelector:(PBPopUpSelector *)popUpSelector didSelectValue:(id)value;
- (void)popUpSelectorDidCancel:(PBPopUpSelector *)popUpSelector;

@end

@interface PBPopUpSelector : UIView <UITableViewDataSource, UITableViewDelegate>

- (instancetype _Nonnull)initWithFrame:(CGRect)frame andValues:(NSArray *)values;
- (void)setupTableView;

@property (nonatomic, strong) NSArray * values;
@property (nonatomic, assign) id<PBPopUpSelectorDelegate> delegate;

@end
