//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerManager.h"

@implementation ChatPickerManager

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.selectedChatModels = [NSMutableArray array];
    }
    return self;
}

- (void)setOutput:(id <ChatPickerManagerOutput>)output
{
    _output = output;
    _output.chatPickerManager = self;
    _output.chatModels = self.chatModels;
}

- (void)setInput:(id <ChatPickerManagerInput>)input
{
    _input = input;
    _input.chatPickerManager = self;
}

- (void)setChatModels:(NSArray *)chatModels
{
    _chatModels = chatModels;
    self.output.chatModels = _chatModels;
}

- (BOOL)isModelSelected:(id<EntityViewModel>)cellModel
{
    return [self.selectedChatModels containsObject:cellModel];
}

- (void)selectCellModel:(id <EntityViewModel>)cellModel
{
    if (self.allowsMultipleSelection)
    {
        [self.selectedChatModels addObject:cellModel];
    }
    else
    {
        [self.selectedChatModels setArray:@[cellModel]];
        [self finishPickingModels];
    }
}

- (void)deselectCellModel:(id <EntityViewModel>)cellModel
{
    if (self.allowsMultipleSelection)
        [self.selectedChatModels removeObject:cellModel];
}

- (void)finishPickingModels
{
    if (![self.selectedChatModels count])
    {
        [self.displayController showSelectUsersError];
        return;
    }

    if ([self.delegate respondsToSelector:@selector(chatPickerManager:didFinishPickingChatModels:)])
        [self.delegate chatPickerManager:self didFinishPickingChatModels:[self.selectedChatModels copy]];
}

- (void)cancelPickingModels
{
    if ([self.delegate respondsToSelector:@selector(chatPickerManagerDidCancel:)])
        [self.delegate chatPickerManagerDidCancel:self];
}

@end