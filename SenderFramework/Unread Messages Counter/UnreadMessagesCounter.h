//
// Created by Roman Serga on 2/11/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Dialog;
@protocol ChatsChangesHandler;
@protocol UpdatesHandler;

@interface UnreadMessagesCounter : NSObject <ChatsChangesHandler, UpdatesHandler>

//@property (nonatomic, readonly) NSInteger unreadMessagesCount_;
@property (nonatomic) BOOL countChatsWithDisabledNotifications;
@property (nonatomic) BOOL countChatsWithDisabledCounter;

- (instancetype)initWithChats:(NSArray<Dialog *>*)chats;

- (NSInteger)unreadMessagesCount;

- (NSInteger)unreadMessagesCountForChatID:(NSString *)chatID;

@end
