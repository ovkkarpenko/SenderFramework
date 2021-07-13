//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerSearchTableDataSource.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation ChatPickerSearchTableDataSource

- (void)setSearchResults:(NSArray <id<EntityViewModel>> *)searchResults
{
    [self setChatModels:searchResults];
}

- (NSArray <id<EntityViewModel>> *)searchResults
{
    return [self chatModels];
}

@end
