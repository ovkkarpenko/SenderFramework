//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatListChatViewModel.h"
#import "NSString+ConvertToLatin.h"
#import "DialogSetting.h"
#import "NSURL+MW_PercentEscapes.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation ChatListChatViewModel
{

}

@synthesize chatTitleLatin = _chatTitleLatin;

- (instancetype)initWithChat:(Dialog *)chat
{
    self = [super init];
    if (self)
    {
        self.chat = chat;
    }
    return self;
}

- (void)setChat:(Dialog *)chat
{
    _chat = chat;
    dispatch_async(dispatch_queue_create("com.MiddleWare.ChatCellModel.nameConverting", DISPATCH_QUEUE_SERIAL), ^{
        _chatTitleLatin = [_chat.name convertedToLatin];
    });
}

- (NSString *)chatTitle
{
    return self.chat.name;
}

- (NSString *)chatSubtitle
{
    NSString * subtitle;

    if ([self.chat.lastMessageText length])
    {
        BOOL textHidden = self.chat.chatSettings.hideTextNotification != ChatSettingsNotificationTypeDisabled;
        subtitle = SenderFrameworkLocalizedString(textHidden ? @"new_msg_gcm" : self.chat.lastMessageText, nil);
    }
    else if ([self.chat.chatDescription length])
    {
        subtitle = self.chat.chatDescription;
    }
    else
    {
        subtitle = SenderFrameworkLocalizedString(@"chat_is_empty", nil);
    }

    return subtitle;
}

- (NSInteger)unreadCount
{
    return [self.chat.unreadCount integerValue];
}

- (ChatType)chatType
{
    return self.chat.chatType;
}

- (NSDate *)lastMessageTime
{
    return self.chat.lastMessageTime;
}

- (BOOL)isFavorite
{
    return [self.chat.chatSettings.favChat boolValue];
}

- (BOOL)isEncrypted
{
    return (self.chatType == ChatTypeP2P && self.chat.p2pBTCKeyData.length > 10) ||
            (self.chatType == ChatTypeGroup && [self.chat isEncrypted]);
}

- (BOOL)isCounterHidden
{
    return self.chat.chatSettings.hideCounterNotification != ChatSettingsNotificationTypeDisabled;
}

- (BOOL)isNotificationsHidden
{
    return self.chat.chatSettings.hidePushNotification != ChatSettingsNotificationTypeDisabled;
}

- (NSURL *)imageURL
{
    return [self.chat.imageURL length] ? [NSURL mw_URLByAddingPercentEscapesToString:self.chat.imageURL] : nil;
}

- (UIImage *)defaultImageWithSize:(CGSize)size rounded:(BOOL)rounded
{
    NSString * backgroundImageName = self.chat.chatType == ChatTypeP2P ? @"icAccount" : nil;
    return [MWDefaultImageGenerator generateDefaultImageWithEmoji:self.chat.defaultImageEmoji
                                                             size:size
                                                          rounded:rounded
                                              backgroundImageName:backgroundImageName];
}

@end