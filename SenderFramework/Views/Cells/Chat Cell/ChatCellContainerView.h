
//
//  ChatCellContainerView.h
//  Sender
//
//  Created by Roman Serga on 31/05/16.
//  Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntityViewModel.h"

@class ChatTableViewCell;
@class ChatCellContainerView;

@protocol ChatCellContainerViewDelegate <NSObject>

- (void)chatCellContainerViewDidPressAccessoryButton:(ChatCellContainerView *)cellContainerView;

@end

@interface ChatCellContainerView : UIView

@property (nonatomic, weak) IBOutlet UIImageView * iconImage;
@property (nonatomic, weak) IBOutlet UILabel * nameLabel;
@property (nonatomic, weak) IBOutlet UILabel * descrLabel;
@property (nonatomic, weak) IBOutlet UIImageView * favImageView;
@property (nonatomic, weak) IBOutlet UIView * unreadCounterBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel * unreadCounterLabel;
@property (nonatomic, weak) IBOutlet UIImageView * typeImage;

@property (nonatomic) BOOL hidesTypeImage;
@property (nonatomic) BOOL hidesUnread;
@property (nonatomic) BOOL hidesFavoriteIndicator;
@property (nonatomic, strong) id<EntityViewModel> cellModel;
@property (nonatomic, weak) id<ChatCellContainerViewDelegate> delegate;

@property (nonatomic, strong) UIView * customAccessory;

+ (ChatCellContainerView *)containerView;

- (void)fixFavoriteIndicator;
- (void)fixColors;

@end
