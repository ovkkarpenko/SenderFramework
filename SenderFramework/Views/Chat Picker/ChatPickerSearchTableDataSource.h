//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperChatListViewController.h"
#import "ChatPickerManager.h"

@protocol ChatSearchManagerOutput;

@interface ChatPickerSearchTableDataSource: SuperChatListViewControllerTableDataSource <ChatSearchManagerOutput, ChatPickerManagerOutput>

@property (nonatomic, strong) NSArray <id<EntityViewModel>> * searchResults;

@end