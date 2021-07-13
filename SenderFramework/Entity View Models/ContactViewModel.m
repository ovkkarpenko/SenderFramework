//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ContactViewModel.h"
#import "NSString+ConvertToLatin.h"
#import "NSURL+MW_PercentEscapes.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation ContactViewModel
{

}

@synthesize chatTitleLatin = _chatTitleLatin;

- (instancetype)initWithContact:(Contact *)contact;
{
    self = [super init];
    if (self)
    {
        self.contact = contact;
    }
    return self;
}

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    dispatch_async(dispatch_queue_create("com.MiddleWare.ChatCellModel.nameConverting", DISPATCH_QUEUE_SERIAL), ^{
        _chatTitleLatin = [_contact.name convertedToLatin];
    });
}

- (NSString *)chatTitle
{
    return self.contact.name;
}

- (NSString *)chatSubtitle
{
    return [self.contact getPhoneFormatted:YES];
}

- (NSInteger)unreadCount
{
    return 0;
}

- (ChatType)chatType
{
    return ChatTypeP2P;
}

- (NSDate *)lastMessageTime
{
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (BOOL)isFavorite
{
    return NO;
}

- (BOOL)isEncrypted
{
    return NO;
}

- (BOOL)isCounterHidden
{
    return YES;
}

- (BOOL)isNotificationsHidden
{
    return YES;
}

- (NSURL *)imageURL
{
    NSURL * imageURL = self.contact.p2pChat != nil ? self.contact.p2pChat.parsedImageURL : self.contact.parsedImageURL;
    if (!imageURL) imageURL = self.contact.parsedImageURL;
    return imageURL;
}

- (UIImage *)defaultImageWithSize:(CGSize)size rounded:(BOOL)rounded
{
    NSString * emoji = self.contact.p2pChat != nil ? self.contact.p2pChat.defaultImageEmoji : self.contact.defaultImageEmoji;
    return [MWDefaultImageGenerator generateDefaultImageWithEmoji:emoji
                                                             size:size
                                                          rounded:rounded
                                              backgroundImageName:@"icAccount"];
}

@end