//
//  ColVewContainer.h
//  SENDER
//
//  Created by Eugene on 1/11/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@interface ColVewContainer : PBSubviewFacade

@property (nonatomic, weak) MainContainerModel * viewModel;
@property (nonatomic, retain) UIView * contentView;
@property (nonatomic, retain) UIView * paddingView;

- (void)doAction;
- (void)correctMarginAndPaddingSize:(PBSubviewFacade *)innerView;

@end
