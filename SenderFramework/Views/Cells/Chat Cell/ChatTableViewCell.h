//
//  ChatTableViewCell.h
//  Sender
//
//  Created by Nick Gromov on 9/10/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntityViewModel.h"
#import "ChatCellContainerView.h"

@class ChatTableViewCell;

@protocol ChatTableViewCellDelegate <NSObject>

@optional

- (void)chatCell:(ChatTableViewCell *)cell willToggleOptions:(BOOL)optionsHidden;
- (void)chatCellDidPressDelete:(ChatTableViewCell *)cell;
- (void)chatCellDidPressFavorite:(ChatTableViewCell *)cell;
- (void)chatCellDidPressAccessoryButton:(ChatTableViewCell *)cell;

@end

@interface ChatTableViewCell : UITableViewCell <ChatCellContainerViewDelegate>
{
    UIView * selectionView;
}

@property (nonatomic) BOOL optionsAreOpen;
@property (nonatomic) BOOL hidesFavoriteButton;
@property (nonatomic) BOOL hidesDeleteButton;
@property (nonatomic) BOOL hidesOptions;
@property (nonatomic) BOOL hidesUnread;
@property (nonatomic) BOOL hidesFavoriteIndicator;
@property (nonatomic) BOOL hidesTypeImage;

@property (nonatomic, strong) id<EntityViewModel> cellModel;

@property (nonatomic, strong) UILongPressGestureRecognizer * longTapRecognizer;
@property (nonatomic, strong) ChatCellContainerView * cellContainerView;
@property (weak, nonatomic) IBOutlet ChatCellContainerView *cellBackgroundView;

@property (nonatomic, weak) id<ChatTableViewCellDelegate> delegate;

- (void)setCustomAccessory:(UIView *)view;

- (void)hideOptions;

@end
