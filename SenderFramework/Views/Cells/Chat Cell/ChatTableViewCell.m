//
//  ChatTableViewCell.m
//  Sender
//
//  Created by Nick Gromov on 9/10/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ChatTableViewCell.h"
#import "Contact.h"
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "PBConsoleConstants.h"
#import "Dialog.h"
#import "CoreDataFacade.h"
#import "SenderNotifications.h"
#import "ServerFacade.h"
#import "Item.h"
#import "DialogSetting.h"
#import "UIView+MWSubviews.h"
#import <SenderFramework/SenderFramework-Swift.h>

#import <libPhoneNumber_iOS/NBPhoneNumberUtil.h>

@interface ChatTableViewCell ()
{
    __weak IBOutlet NSLayoutConstraint * leftOffset;
    __weak IBOutlet NSLayoutConstraint * rightOffset;
    __weak IBOutlet NSLayoutConstraint * favButtonWidth;
    __weak IBOutlet NSLayoutConstraint * delButtonWidth;
    __weak IBOutlet UIButton * favButton;
    __weak IBOutlet UIButton * deleteButton;
}

@end

@implementation ChatTableViewCell

- (void)awakeFromNib
{
    self.cellContainerView = [ChatCellContainerView containerView];
    self.cellContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cellBackgroundView addSubview:self.cellContainerView];
    [self.cellBackgroundView mw_pinSubview:self.cellContainerView];

    self.longTapRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongTap:)];
    [self addGestureRecognizer:self.longTapRecognizer];
    
    deleteButton.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor];
    favButton.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];

    selectionView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView = selectionView;
    [self layoutIfNeeded];
}

- (void)dealloc
{
    [self.longTapRecognizer removeTarget:self action:@selector(handleLongTap:)];
}

- (void)setHidesUnread:(BOOL)hidesUnread
{
    self.cellContainerView.hidesUnread = hidesUnread;
}

- (BOOL)hidesUnread
{
    return self.cellContainerView.hidesUnread;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected)
    {
        [self fixColors];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (highlighted)
    {
        [self fixColors];
    }
}

- (void)setHidesTypeImage:(BOOL)hidesTypeImage
{
    self.cellContainerView.hidesTypeImage = hidesTypeImage;
}

- (BOOL)hidesTypeImage
{
    return self.cellContainerView.hidesTypeImage;
}

- (void)setCellModel:(id <EntityViewModel>)cellModel
{
    _cellModel = cellModel;
    self.cellContainerView.cellModel = _cellModel;
    [self fixFavoriteIndicator];
    UIColor * backgroundColour = [[SenderCore sharedCore].stylePalette mainAccentColor];
    selectionView.backgroundColor = backgroundColour;
}

- (void)fixColors
{
    deleteButton.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor];
    favButton.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    [self.cellContainerView fixColors];
}

- (void)fixFavoriteIndicator
{
    [self.cellContainerView fixFavoriteIndicator];
}

- (void)handleLongTap:(UILongPressGestureRecognizer *)recognizer
{
    [self showOptions];
}

- (void)showOptions
{
    if (!self.optionsAreOpen)
        [self toggleOptionsAnimated:YES];
}

- (void)hideOptions
{
    if (self.optionsAreOpen)
        [self toggleOptionsAnimated:YES];
}

- (void)prepareForReuse
{
    [self.cellContainerView.iconImage sd_cancelCurrentImageLoad];
    if (self.optionsAreOpen)
        [self toggleOptionsAnimated:NO];
    self.hidesDeleteButton = NO;
    self.hidesFavoriteButton = NO;
    [self.cellContainerView.typeImage sd_cancelCurrentImageLoad];
}

- (void)toggleOptionsAnimated:(BOOL)animated
{
    self.optionsAreOpen = !self.optionsAreOpen;

    if ([self.delegate respondsToSelector:@selector(chatCell:willToggleOptions:)])
        [self.delegate chatCell:self willToggleOptions:self.optionsAreOpen];
    
    if (self.optionsAreOpen)
    {
        favButton.hidden = NO;
        deleteButton.hidden = NO;
        rightOffset.constant = (favButton.frame.size.width + deleteButton.frame.size.width);
        leftOffset.constant -= (favButton.frame.size.width + deleteButton.frame.size.width);
    }
    else
    {
        CGFloat deltaX = leftOffset.constant + (favButton.frame.size.width + deleteButton.frame.size.width);
        leftOffset.constant += (favButton.frame.size.width + deleteButton.frame.size.width);
        rightOffset.constant = deltaX;
    }

    if (animated)
    {
        [UIView animateWithDuration:0.3f animations:^{
            [self layoutIfNeeded];
        }completion:^(BOOL finished) {
            favButton.hidden = !self.optionsAreOpen;
            deleteButton.hidden = !self.optionsAreOpen;
            self.longTapRecognizer.enabled = !self.optionsAreOpen;
        }];
    }
    else
    {
        [self layoutIfNeeded];
        favButton.hidden = !self.optionsAreOpen;
        deleteButton.hidden = !self.optionsAreOpen;
        self.longTapRecognizer.enabled = !self.optionsAreOpen;
    }
}

- (void)setHidesFavoriteButton:(BOOL)hidesFavoriteButton
{
    _hidesFavoriteButton = hidesFavoriteButton;
    favButtonWidth.constant = _hidesFavoriteButton ? 0.0f : 100.0f;
    [self layoutIfNeeded];
}

- (void)setHidesDeleteButton:(BOOL)hidesDeleteButton
{
    _hidesDeleteButton = hidesDeleteButton;
    delButtonWidth.constant = _hidesDeleteButton ? 0.0f : 100.0f;
    [self layoutIfNeeded];
}

- (void)setHidesOptions:(BOOL)hidesOptions
{
    _hidesOptions = hidesOptions;
    favButtonWidth.constant = delButtonWidth.constant = _hidesOptions ? 0.0f : 100.0f;
    [self layoutIfNeeded];
}

- (void)setHidesFavoriteIndicator:(BOOL)hidesFavoriteIndicator
{
    self.cellContainerView.hidesFavoriteIndicator = hidesFavoriteIndicator;
}

- (void)setCustomAccessory:(UIView *)view
{
    self.cellContainerView.customAccessory = view;
}

- (IBAction)favButtonPushed:(id)sender
{
    [self toggleOptionsAnimated:YES];

    if ([self.delegate respondsToSelector:@selector(chatCellDidPressFavorite:)])
        [self.delegate chatCellDidPressFavorite:self];
}

- (IBAction)deleteContact:(id)sender
{
    [self toggleOptionsAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(chatCellDidPressDelete:)])
        [self.delegate chatCellDidPressDelete:self];
}

#pragma mark - ChatCellContainerView Delegate

- (void)chatCellContainerViewDidPressAccessoryButton:(ChatCellContainerView *)cellContainerView
{
    if ([self.delegate respondsToSelector:@selector(chatCellDidPressAccessoryButton:)])
        [self.delegate chatCellDidPressAccessoryButton:self];
}

@end
