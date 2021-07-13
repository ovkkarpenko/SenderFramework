//
// Created by Roman Serga on 2/11/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "UnreadMessagesCounter.h"
#import "Dialog.h"
#import "DialogSetting.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface UnreadMessagesCounter()

@property (nonatomic, readwrite) NSInteger unreadMessagesCount_;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*>* unreadChatsCounters;

@end

@implementation UnreadMessagesCounter

- (instancetype)init
{
    return [self initWithChats:@[]];
}

- (NSInteger)unreadMessagesCount
{
    @synchronized (self) {
        return self.unreadMessagesCount_;
    }
}
- (instancetype)initWithChats:(NSArray<Dialog *>*)chats
{
    self = [super init];
    if (self)
    {
        self.unreadMessagesCount_ = 0;
        self.unreadChatsCounters = [NSMutableDictionary dictionary];
        for (Dialog * chat in chats) [self handleChatChange:chat];
    }
    return self;
}

- (BOOL)handleChatChange:(Dialog *)chat
{
    if (!chat.chatID) return NO;

    BOOL chatUnreadCountHasChanged = NO;
    @synchronized (self)
    {
        NSInteger cachedChatUnreadCount = [(self.unreadChatsCounters[chat.chatID] ?: @0) integerValue];
        NSInteger newChatUnreadCount = [chat.unreadCount integerValue];

        if ((!self.countChatsWithDisabledCounter && ![chat.chatSettings.ntfCounter isEqualToString:@"off"]) ||
            (!self.countChatsWithDisabledNotifications && ![chat.chatSettings.ntfHidePush isEqualToString:@"off"]))
            newChatUnreadCount = 0;

        NSInteger delta = newChatUnreadCount - cachedChatUnreadCount;

        if (delta != 0)
        {
            chatUnreadCountHasChanged = YES;
            self.unreadMessagesCount_ += delta;
        }

        if (self.unreadMessagesCount_ > 99) self.unreadMessagesCount_ = 99;

        self.unreadChatsCounters[chat.chatID] = (newChatUnreadCount > 0) ? @(newChatUnreadCount) : nil;
    }
    return chatUnreadCountHasChanged;
}

-(void)handleChatsChange:(NSArray<Dialog *> *)chats
{
    BOOL areChatsUpdated = NO;
    for (Dialog * chat in chats)
    {
        if ([self handleChatChange:chat])
            areChatsUpdated = YES;
    }
    if (areChatsUpdated)
        [[SenderCore sharedCore].interfaceUpdater unreadMessagesCountWasChanged:self.unreadMessagesCount_];
}

- (NSInteger)unreadMessagesCountForChatID:(NSString *)chatID
{
    if (!chatID)
        return 0;
    NSNumber * unreadCount = self.unreadChatsCounters[chatID];
    return unreadCount != nil ? [unreadCount integerValue] : 0;
}

@end
