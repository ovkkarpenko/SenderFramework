//
// Created by Roman Serga on 30/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatListStorage : NSObject

@property (nonatomic, strong) NSMutableArray * favorite;
@property (nonatomic, strong) NSMutableArray * users;
@property (nonatomic, strong) NSMutableArray * companies;
@property (nonatomic, strong) NSMutableArray * groups;
@property (nonatomic, strong) NSMutableArray * opers;

- (NSArray *)allChats;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSUInteger)count;
- (BOOL)isEmpty;

/*
    Returns one of category arrays of chatStorage (favorite, users, etc.) that contains chat.
    Returns nil, if neither of them contains chat.
    If mutiple arrays contains chat, returns one of them.
 */
- (NSMutableArray *)categoryArrayOfChat:(id)chat;

@end
