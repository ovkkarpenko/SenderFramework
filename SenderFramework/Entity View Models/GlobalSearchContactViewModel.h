//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityViewModel.h"


@class ActionCellModel;

@interface GlobalSearchContactViewModel : NSObject <EntityViewModel>

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

- (UIImage *)defaultImageWithSize:(CGSize)size rounded:(BOOL)rounded;

#pragma mark - GlobalSearchResult Properties

@property (nonatomic, strong, readonly) NSString * userID;
@property (nonatomic, strong, readonly) NSString * phone;
@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, strong, readonly) NSString * description;
@property (nonatomic, strong, readonly) NSString * photoURLString;
@property (nonatomic, readonly) BOOL isCompany;

@property (nonatomic, strong) NSDictionary * modelDictionary;
@property (nonatomic, strong) NSArray<ActionCellModel *>* actions;

- (_Nonnull instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end