//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperChatListViewController.h"
#import "ChatPickerManager.h"

@protocol ChatSearchManagerInput;
@class ChatSearchManager;
@protocol EntityPickerPresenterProtocol;

@interface ChatPickerViewControllerTableDelegate: SuperChatListViewControllerTableDelegate <ChatSearchManagerInput, ChatPickerManagerInput>

@property (nonatomic, strong, nullable) id<EntityPickerPresenterProtocol> presenter;
@property (nonatomic, weak) ChatSearchManager * chatSearchManager;

@end
