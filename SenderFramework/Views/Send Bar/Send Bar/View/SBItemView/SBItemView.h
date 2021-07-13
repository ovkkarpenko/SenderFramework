//
//  SBItemView.h
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarItem.h"

@class SBItemView;

@protocol SBItemViewDelegate <NSObject>

-(void)itemView:(SBItemView*)itemView didChooseActionsWithData:(NSArray *)actionsData;

@end

@interface SBItemView : UIView
{
    @protected __weak UIButton * _actionButton;
    @protected __weak UILabel * _titleLabel;
    @protected __weak NSLayoutConstraint * _titleLabelHeight;
}

-(instancetype)initWithFrame:(CGRect)frame andItemModel:(BarItem *)itemModel;
-(instancetype)initWithItemModel:(BarItem *)itemModel;

@property (nonatomic, strong) BarItem * itemModel;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL hidesTitle;
@property (nonatomic, weak) id<SBItemViewDelegate> delegate;
@property (nonatomic, strong) UIColor * titleTextColor;

@end
