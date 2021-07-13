//
// Created by Roman Serga on 27/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWLastActiveChatCoordinator.h"
#import "Message.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import <SenderFramework/SenderFramework.h>

@implementation MWLastActiveChatModel
- (instancetype)initWithChat:(Dialog *)chat
{
    self = [super init];
    if (self)
    {
        self.chatID = chat.chatID;
        self.chatName = chat.name;
        self.chatType = chat.chatType;
        self.lastUpdateTime = chat.lastMessageTime;
    }
    return self;
}

@end

@interface MWLastActiveChatCoordinator()

@property (nonatomic, strong, readwrite) NSArray<MWLastActiveChatModel *>* lastActiveChats;

@property (nonatomic, strong) MWLastActiveChatModel * lastActiveP2PChat;
@property (nonatomic, strong) MWLastActiveChatModel * lastActiveGroupChat;

@end

@implementation MWLastActiveChatCoordinator
{

}

#pragma mark - MessagesChangesHandler

-(void)handleMessagesUpdate:(NSArray<Message *> *)updatedMessages
{
    [self handleMessagesChanges:updatedMessages];
}

-(void)handleMessagesAdding:(NSArray<Message *> *)newMessages
{
    [self handleMessagesChanges:newMessages];
}

-(void)handleMessagesRemoval:(NSArray<Message *> *)removedMessages
{
    [self handleMessagesChanges:removedMessages];
}

-(void)handleMessagesChanges:(NSArray<Message *> *)changedMessages
{
    for (Message * message in changedMessages)
    {
        Dialog * chat = message.dialog;
        if (!(chat.isP2P || chat.isGroup))
            continue;

        MWLastActiveChatModel * updatedModel;
        [self updateLastActiveChatModel:&updatedModel withChat:chat];

        if (updatedModel)
        {
            if (chat.isP2P)
                self.lastActiveP2PChat = updatedModel;
            else
                self.lastActiveGroupChat = updatedModel;
        }
    }
}

- (void)updateLastActiveChatModel:(MWLastActiveChatModel **)lastActiveChatModelPointer withChat:(Dialog *)chat
{
    if (![chat lastMessageTime] || !chat.chatID)
        return;

    MWLastActiveChatModel * lastActiveChatModel = *lastActiveChatModelPointer;
    if (!lastActiveChatModel.lastUpdateTime ||
        [lastActiveChatModel.lastUpdateTime compare:chat.lastMessageTime] == NSOrderedAscending)
    {
        *lastActiveChatModelPointer = [[MWLastActiveChatModel alloc] initWithChat:chat];
    }
}

- (NSArray<MWLastActiveChatModel *> *)lastActiveChats
{
    NSMutableArray * lastActiveChatsMutable = [NSMutableArray array];
    if (self.lastActiveP2PChat)
        [lastActiveChatsMutable addObject:self.lastActiveP2PChat];
    if (self.lastActiveGroupChat)
        [lastActiveChatsMutable addObject:self.lastActiveGroupChat];
    return [lastActiveChatsMutable copy];
}

@end