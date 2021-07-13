//
//  ChatListViewController+UpdatesHandling.m
//  SENDER
//
//  Created by Roman Serga on 7/6/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "ChatListViewController+UpdatesHandling.h"
#import "Message.h"
#import "ParamsFacade.h"
#import "ChatListStorage.h"
#import "objc/runtime.h"
#import "ChatListChatViewModel.h"

@implementation ChatListViewController (UpdatesHandling)

-(void)addCellModel:(ChatListChatViewModel *)cellModel
{
    if (cellModel.isFavorite)
        [chatStorage.favorite addObject:cellModel];

    switch (cellModel.chatType) {
        case ChatTypeOperator:
            [chatStorage.opers addObject:cellModel];
            break;
        case ChatTypeGroup:
            [chatStorage.groups addObject:cellModel];
            break;
        case ChatTypeP2P:
            [chatStorage.users addObject:cellModel];
            break;
        case ChatTypeCompany:
            [chatStorage.companies addObject:cellModel];
            break;
        case ChatTypeUndefined:break;
    }
}

-(void)deleteCellModel:(ChatListChatViewModel *)cellModel
{
    if ([chatStorage.favorite containsObject:cellModel])
        [chatStorage.favorite removeObject:cellModel];
    
    NSMutableArray * categoryArray = [chatStorage categoryArrayOfChat:cellModel];
    [categoryArray removeObject:cellModel];
}

#pragma mark - ChatsChangesHandler

-(void)handleChatsChange:(NSArray<Dialog *> *)chats
{
    //    [self runInUpdateQueue:^{

    NSMutableSet * updatedModels = [NSMutableSet set];
    NSMutableSet * newObjects = [NSMutableSet set];
    NSMutableSet * deletedModels = [NSMutableSet set];

    for (Dialog * chat in chats)
    {
        BOOL isDeletedObject = (chat.chatState == ChatStateRemoved || chat.chatState == ChatStateUndefined);
        BOOL isNewModel = !isDeletedObject;

        for (NSUInteger idx = 0; idx < [chatStorage count]; idx++)
        {
            ChatListChatViewModel *cellModel = chatStorage[idx];

            if (chat.chatID)
            {
                if ([cellModel.chat.chatID isEqual:chat.chatID])
                {
                    isNewModel = NO;

                    if (isDeletedObject)
                        [deletedModels addObject:cellModel];
                    else
                        [updatedModels addObject:cellModel];
                }
            }
        }
        if (isNewModel)
            [newObjects addObject:chat];
    }

    [self deleteCellModels:[deletedModels copy]];
    [self updateCellModels:[updatedModels copy]];
    [self addNewCellModelsForObjects:[newObjects copy]];

    NSArray * sortDescriptors = [[ParamsFacade sharedInstance] getSortDescriptorsBy:@"lastMessageTime"
                                                                                  ascending:NO];
    [mainArray sortUsingDescriptors:sortDescriptors];

//        dispatch_async(dispatch_get_main_queue(), ^(void) {

    [self.updateTimer invalidate];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[NSBlockOperation blockOperationWithBlock:^{
        [self reloadAllCategoryCounters];
        [self reloadCurrentCategory];
        [self updateCategoryButtons];
    }] selector:@selector(main) userInfo:nil repeats:NO];

//        });
//    }];
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
    NSMutableArray * updatedChats = [NSMutableArray array];
    for (Message * message in changedMessages) {
        if (message.dialog)
        {
            if (![updatedChats containsObject:message.dialog])
                [updatedChats addObject:message.dialog];
        }
    }
    if ([updatedChats count])
        [self handleChatsChange:[updatedChats copy]];
}

#pragma mark - TableView updating methods

-(void)addNewCellModelsForObjects:(NSSet<Dialog *> *)newChats
{
    for (Dialog * chat in newChats)
    {
        ChatListChatViewModel * cellModel = [[ChatListChatViewModel alloc] initWithChat:chat];
        [self addCellModel:cellModel];
    }
}

-(void)updateCellModels:(NSSet<ChatListChatViewModel *>*)models
{
    for (ChatListChatViewModel * model in models)
    {
        BOOL oldIsFavorite = [chatStorage.favorite containsObject:model];
        
        if (model.isFavorite) {
            if (!oldIsFavorite) {
                [chatStorage.favorite addObject:model];
                [self reloadAllCategoryCounters];
            }
        }
        else {
            if (oldIsFavorite) {
                [chatStorage.favorite removeObject:model];
                [self reloadAllCategoryCounters];
            }
        }

        NSMutableArray * currentCategoryArray = [chatStorage categoryArrayOfChat:model];
        NSMutableArray * trueCategoryArray = [self categoryArrayForChatType:model.chatType];
        
        if (currentCategoryArray != trueCategoryArray)
        {
            [self deleteCellModel:model];
            [self addCellModel:model];
        }
    }
}

-(void)deleteCellModels:(NSSet<ChatListChatViewModel *>*)models
{
    for (ChatListChatViewModel * model in models)
    {
        [self deleteCellModel:model];
    }
    [self reloadAllCategoryCounters];
}

- (void)reloadAllCategoryCounters
{
    senderUnread = [self getUnreadChatsCount:chatStorage.users includeFavorites:NO];
    groupUnread = [self getUnreadChatsCount:chatStorage.groups includeFavorites:NO];
    favUnread = [self getUnreadChatsCount:chatStorage.favorite includeFavorites:YES];
    companiesUnread = [self getUnreadChatsCount:chatStorage.companies includeFavorites:NO];
}

- (NSInteger)getUnreadChatsCount:(NSArray <ChatListChatViewModel *> *)models includeFavorites:(BOOL)includeFavorites
{
    NSInteger unreadCount = 0;
    
    for (ChatListChatViewModel * model in models)
    {
        BOOL countModel = !model.isFavorite || includeFavorites;
        if (countModel && model.unreadCount > 0 && !model.isNotificationsHidden && !model.isCounterHidden)
            unreadCount ++;
    }
    
    return unreadCount;
}

-(dispatch_queue_t)getUpdateQueue
{
    dispatch_queue_t updateQueue;
    updateQueue = objc_getAssociatedObject(self, @selector(getUpdateQueue));
    if (!updateQueue)
    {
        updateQueue = dispatch_queue_create("com.MiddleWare.SENDER.dialogsUpdate", NULL);
        objc_setAssociatedObject(self, @selector(getUpdateQueue), updateQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return updateQueue;
}

-(void)runInUpdateQueue:(dispatch_block_t)block
{
    dispatch_queue_t updateQueue = [self getUpdateQueue];
    dispatch_async(updateQueue, block);
}

-(void)setUpdateTimer:(NSTimer *)timer
{
    objc_setAssociatedObject(self, @selector(updateTimer), timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSTimer *)updateTimer
{
    NSTimer * timer = objc_getAssociatedObject(self, @selector(updateTimer));
    return timer;
}

@end
