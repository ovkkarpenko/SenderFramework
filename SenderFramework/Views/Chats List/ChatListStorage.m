//
// Created by Roman Serga on 30/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatListStorage.h"

@implementation ChatListStorage

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.favorite = [NSMutableArray array];
        self.users = [NSMutableArray array];
        self.companies = [NSMutableArray array];
        self.groups = [NSMutableArray array];
        self.opers = [NSMutableArray array];
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    NSInteger favoriteChatsCount = [self.favorite count];
    NSInteger userChatsCount = [self.users count];
    NSInteger companyChatsCount = [self.companies count];
    NSInteger groupChatsCount = [self.groups count];

    if (idx < favoriteChatsCount)
        return self.favorite[idx];
    else if (idx >= favoriteChatsCount && idx < (favoriteChatsCount + userChatsCount))
        return self.users[idx - favoriteChatsCount];
    else if (idx >= (favoriteChatsCount + userChatsCount) && idx < (favoriteChatsCount + userChatsCount + companyChatsCount))
        return self.companies[idx - favoriteChatsCount - userChatsCount];
    else if (idx >= (favoriteChatsCount + userChatsCount + companyChatsCount) && idx < (favoriteChatsCount + userChatsCount + companyChatsCount + groupChatsCount))
        return self.groups[idx - favoriteChatsCount - userChatsCount - companyChatsCount];
    else
        return nil;
}

-(NSArray *)allChats
{
    return [[self.users arrayByAddingObjectsFromArray:self.companies]arrayByAddingObjectsFromArray:self.groups];
}

-(NSUInteger)count
{
    return [self.favorite count] + [self.users count] + [self.companies count] + [self.groups count];
}

- (BOOL)isEmpty
{
    return ![self.favorite count] &&
            ![self.users count] &&
            ![self.companies count] &&
            ![self.groups count] &&
            ![self.opers count];
}

/*
 * Temporary always returning empty array of operator chata
 */
-(NSMutableArray *)opers
{
    return [NSMutableArray array];
}

- (NSMutableArray *)categoryArrayOfChat:(id)chat
{
    if ([self.favorite containsObject:chat])
        return self.favorite;
    else if ([self.users containsObject:chat])
        return self.users;
    else if ([self.companies containsObject:chat])
        return self.companies;
    else if ([self.groups containsObject:chat])
        return self.groups;
    else if ([self.opers containsObject:chat])
        return self.opers;
    
    return nil;
}

@end
