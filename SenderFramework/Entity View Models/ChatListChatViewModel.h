//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityViewModel.h"

@interface ChatListChatViewModel : NSObject <EntityViewModel>

#pragma mark - EntityViewModel Properties

@property (nonatomic, strong, readonly) NSString * chatTitle;
@property (nonatomic, strong, readonly) NSString * chatTitleLatin;
@property (nonatomic, strong, readonly) NSString * chatSubtitle;

@property (nonatomic, readonly) NSInteger unreadCount;
@property (nonatomic, readonly) ChatType chatType;
@property (nonatomic, strong, readonly) NSDate * lastMessageTime;

@property (nonatomic, readonly) BOOL isFavorite;
@property (nonatomic, readonly) BOOL isEncrypted;
@property (nonatomic, readonly) BOOL isCounterHidden;
@property (nonatomic, readonly) BOOL isNotificationsHidden;

@property (nonatomic, strong, readonly) NSURL * imageURL;
@property (nonatomic, strong, readonly) UIImage * defaultImage;

- (UIImage *)defaultImageWithSize:(CGSize)size rounded:(BOOL)rounded;

#pragma mark - ChatViewModel Properties

- (instancetype)initWithChat:(Dialog *)chat;

@property (nonatomic, strong) Dialog * chat;
@property (nonatomic) NSInteger categoryCounter;

@end
