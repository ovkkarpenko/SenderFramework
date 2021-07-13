//
//  PBSelectedView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "PBPopUpSelector.h"

@class PBSelectedView;

@protocol PBSelectedViewDelegate <PBSubviewDelegate>

- (void)selectValueFromValues:(NSArray *)values forSelectView:(PBSelectedView *)selectView;

@end

@interface PBSelectedView : PBSubviewFacade

@property (nonatomic, weak) id<PBSelectedViewDelegate> delegate;

@property (nonatomic, strong) UITextField * inputTextField;
@property (nonatomic, weak) MainContainerModel * viewModel;

- (void)setSelectedValue:(NSDictionary *)selectedValue;

@end
