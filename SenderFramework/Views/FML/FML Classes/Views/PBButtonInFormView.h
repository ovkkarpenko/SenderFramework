//
//  PBButtonInFormView.h
//  SENDER
//
//  Created by Eugene on 10/25/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@class PBButtonInFormView;

@protocol PBButtonInFormViewDelegate <PBSubviewDelegate>

- (void)pushOnButton:(PBButtonInFormView *)controller didFinishEnteringItem:(NSDictionary *)buttonInfo;

@end

@interface PBButtonInFormView : PBSubviewFacade

@property (nonatomic, strong) UIButton * doneButton;
@property (nonatomic, assign) id<PBButtonInFormViewDelegate> delegate;
@property (nonatomic, weak) MainContainerModel * viewModel;

@end
