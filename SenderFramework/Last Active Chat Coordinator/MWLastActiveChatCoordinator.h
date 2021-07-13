//
// Created by Roman Serga on 27/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dialog.h"

@protocol MessagesChangesHandler;

@interface MWLastActiveChatModel: NSObject

@property (nonatomic, strong) NSString * chatName;
@property (nonatomic, strong) NSString * chatID;
@property (nonatomic) ChatType chatType;
@property (nonatomic, strong) NSDate * lastUpdateTime;

- (instancetype)initWithChat:(Dialog *)chat;


@end

@interface MWLastActiveChatCoordinator : NSObject <MessagesChangesHandler>

@property (nonatomic, strong, readonly) NSArray<MWLastActiveChatModel *>* lastActiveChats;

@end