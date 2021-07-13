//
// Created by Roman Serga on 1/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatListChatViewModel;
@class ChatSearchManager;

@protocol EntityViewModel;
@protocol ChatSearchManagerDelegate;
@protocol ChatSearchManagerOutput;
@protocol ChatSearchManagerInput;

@protocol EntityPickerViewProtocol;
@protocol EntityPickerPresenterProtocol;

#import "Contact.h"
#import "SuperChatListViewController.h"
#import "ChatPickerManager.h"

@interface ChatPickerViewController : SuperChatListViewController <UISearchControllerDelegate,
        ChatPickerManagerInput, ChatPickerManagerDisplayController, EntityPickerViewProtocol>

@property (nonatomic, strong) ChatPickerSearchTableDataSource * pickerTableDataSource;
@property (nonatomic, strong) ChatPickerViewControllerTableDelegate * pickerTableDelegate;

@property (nonatomic, strong) ChatPickerSearchTableDataSource * searchTableDataSource;

@property (nonatomic, strong, nullable) id<EntityPickerPresenterProtocol> presenter;

@end
