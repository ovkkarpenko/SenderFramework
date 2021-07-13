//
//  ChatCellContainerView.m
//  Sender
//
//  Created by Roman Serga on 31/05/16.
//  Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "ChatCellContainerView.h"
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

#import <libPhoneNumber_iOS/NBPhoneNumberUtil.h>

@interface ChatCellContainerView ()
{
    __weak IBOutlet UIButton * customAccessoryContainer;
    __weak IBOutlet NSLayoutConstraint * typeImageWidth;
    __weak IBOutlet NSLayoutConstraint * contactNameLeading;
}

@end

@implementation ChatCellContainerView

+ (ChatCellContainerView *)containerView
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    UIView * viewFromNib = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"ChatCellContainerView"
                                                                            owner:nil
                                                                          options:nil] firstObject];
    return (ChatCellContainerView *)viewFromNib;
}

- (void)awakeFromNib
{
    self.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];

    UIFont * titleFont = [UIFont systemFontOfSize:16.0f weight:UIFontWeightMedium];
    self.nameLabel.font = titleFont;
    self.descrLabel.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];

    UIFont * unreadCounterFont = [UIFont systemFontOfSize:16.0f weight:UIFontWeightLight];
    self.unreadCounterLabel.font = unreadCounterFont;
    self.unreadCounterBackgroundView.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor];
    self.unreadCounterBackgroundView.clipsToBounds = YES;

    self.iconImage.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImage.clipsToBounds = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.iconImage.layer.cornerRadius = self.iconImage.frame.size.width / 2;
    self.unreadCounterBackgroundView.layer.cornerRadius = self.unreadCounterBackgroundView.frame.size.height / 2;
    self.favImageView.layer.cornerRadius = self.favImageView.frame.size.height / 2;
}

- (void)setCellModel:(id <EntityViewModel>)cellModel
{
    _cellModel = cellModel;

    [self.iconImage sd_cancelCurrentImageLoad];
    UIImage * placeHolder = [_cellModel defaultImageWithSize:self.iconImage.frame.size rounded:YES];
    [self.iconImage sd_setImageWithURL:_cellModel.imageURL placeholderImage:placeHolder];
    self.nameLabel.text = _cellModel.chatTitle;
    self.descrLabel.text = _cellModel.chatSubtitle;
    [self fixFavoriteIndicator];
    [self fixUnreadCount];

    if (_cellModel.isEncrypted) {
        [self.typeImage setTintColor:[SenderCore sharedCore].stylePalette.bitcoinColor];
        self.nameLabel.textColor = [[SenderCore sharedCore].stylePalette mainTextColor];

        [self.typeImage setImage:[UIImage imageFromSenderFrameworkNamed:@"locked"]];
        [self setHidesTypeImage:NO];
    }
    else {
        [self setHidesTypeImage:YES];
        [self.typeImage setTintColor:[SenderCore sharedCore].stylePalette.lineColor];
        self.nameLabel.textColor = [[SenderCore sharedCore].stylePalette mainTextColor];
    }
}

- (void)setHidesTypeImage:(BOOL)hidesTypeImage
{
    _hidesTypeImage = hidesTypeImage;
    typeImageWidth.constant = hidesTypeImage ? 0.0f : 16.0f;
    contactNameLeading.constant = hidesTypeImage ? 0.0f : 5.0f;
}

-(void)setHidesFavoriteIndicator:(BOOL)hidesFavoriteIndicator
{
    _hidesFavoriteIndicator = hidesFavoriteIndicator;
    self.favImageView.hidden = _hidesFavoriteIndicator;
}

- (void)setCustomAccessory:(UIView *)customAccessory
{
    _customAccessory = customAccessory;
    for (UIView * subview in customAccessoryContainer.subviews) {
        [subview removeFromSuperview];
    }
    [customAccessoryContainer addSubview:customAccessory];
    customAccessory.userInteractionEnabled = NO;
    customAccessoryContainer.hidden = !customAccessory;
}

-(void)setHidesUnread:(BOOL)hidesUnread
{
    _hidesUnread = hidesUnread;
    [self fixUnreadCount];
}

-(void)fixColors
{
    self.favImageView.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    self.iconImage.backgroundColor = [UIColor whiteColor];
}

-(void)fixUnreadCount
{
    if (self.hidesUnread || self.cellModel.unreadCount < 1 || [self.cellModel isCounterHidden])
    {
        self.unreadCounterBackgroundView.hidden = YES;
    }
    else
    {
        self.unreadCounterBackgroundView.hidden = NO;
        self.unreadCounterLabel.text = [NSString stringWithFormat:@"%li", (long)self.cellModel.unreadCount];
    }
}

- (void)fixFavoriteIndicator
{
    self.favImageView.hidden = !self.cellModel.isFavorite;
}

- (IBAction)accessoryButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(chatCellContainerViewDidPressAccessoryButton:)])
        [self.delegate chatCellContainerViewDidPressAccessoryButton:self];
}

@end
