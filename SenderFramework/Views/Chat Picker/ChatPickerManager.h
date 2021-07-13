//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SuperChatListViewController.h"

@class ChatPickerSearchTableDataSource;
@class ChatPickerViewControllerTableDelegate;
@class ChatPickerManager;

@protocol ChatPickerManagerDelegate <NSObject>

- (void)chatPickerManager:(ChatPickerManager *)chatPickerViewController didFinishPickingChatModels:(NSArray <id<EntityViewModel>> *)chatModels;
- (void)chatPickerManagerDidCancel:(ChatPickerManager *)chatPickerViewController;

@end

@protocol ChatPickerManagerOutput <NSObject>

@property (nonatomic, weak) ChatPickerManager * chatPickerManager;
@property (nonatomic, strong) NSArray<id<EntityViewModel>> * chatModels;

@end

@protocol ChatPickerManagerInput <NSObject>

@property (nonatomic, weak) ChatPickerManager * chatPickerManager;

@end

@protocol ChatPickerManagerDisplayController <NSObject>

@property (nonatomic, weak) ChatPickerManager * chatPickerManager;

- (void)showSelectUsersError;

@end

@interface ChatPickerManager: NSObject

@property (nonatomic, strong) NSArray<id<EntityViewModel>> * chatModels;
@property (nonatomic, strong) NSMutableArray<id<EntityViewModel>> * selectedChatModels;

@property (nonatomic, strong) id<ChatPickerManagerOutput> output;
@property (nonatomic, strong) id<ChatPickerManagerInput> input;

@property (nonatomic, strong) id<ChatPickerManagerDisplayController> displayController;

@property (nonatomic) BOOL allowsMultipleSelection;

@property (nonatomic, weak) id<ChatPickerManagerDelegate> delegate;

- (BOOL)isModelSelected:(id<EntityViewModel>)cellModel;

- (void)selectCellModel:(id<EntityViewModel>)cellModel;
- (void)deselectCellModel:(id<EntityViewModel>)cellModel;

- (void)finishPickingModels;
- (void)cancelPickingModels;

@end
