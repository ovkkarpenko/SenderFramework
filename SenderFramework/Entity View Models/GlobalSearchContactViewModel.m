//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "GlobalSearchContactViewModel.h"
#import "NSString+ConvertToLatin.h"
#import "ActionCellModel.h"
#import "NSURL+MW_PercentEscapes.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface GlobalSearchContactViewModel()

@property (nonatomic, strong, readwrite) NSString * chatTitle;
@property (nonatomic, strong, readwrite) NSString * chatTitleLatin;
@property (nonatomic, strong, readwrite) NSString * chatSubtitle;

@property (nonatomic, readwrite) ChatType chatType;
@property (nonatomic, strong, readwrite) NSURL * imageURL;

@property (nonatomic, strong, readwrite) UIColor * defaultImageBackgroundColor;
@property (nonatomic, strong, readwrite) UIImage * defaultImage;

@end

@implementation GlobalSearchContactViewModel
{

}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.modelDictionary = dictionary;
    }
    return self;
}

- (void)setModelDictionary:(NSDictionary *)modelDictionary
{
    _modelDictionary = modelDictionary;
    [self updateWithDictionary:_modelDictionary];
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    if (dictionary[@"type"]) {
        if (dictionary[@"name"])
            self.chatTitle = [dictionary[@"name"] description];
        if (dictionary[@"description"])
            self.chatSubtitle = [dictionary[@"description"] description];
        if (dictionary[@"photo"])
            self.imageURL = [NSURL mw_URLByAddingPercentEscapesToString:dictionary[@"photo"]];

        if (dictionary[@"actions"] && [dictionary[@"actions"] isKindOfClass:[NSArray class]])
        {
            NSMutableArray * actionsMutable = [NSMutableArray array];
            NSArray * actions = dictionary[@"actions"];
            for (NSDictionary * actionsDictionary in actions)
            {
                ActionCellModel * actionModel = [[ActionCellModel alloc] initWithDictionary:actionsDictionary];
                [actionsMutable addObject:actionModel];
            }
            self.actions = actionsMutable;
        }

        /*
         * Currently we can find only companies and their actions in global search.
         * So we'll set ChatTypeCompany as chatType
         */
        self.chatType = ChatTypeCompany;
    }
}

-(void)setChatTitle:(NSString *)chatTitle
{
    _chatTitle = chatTitle;
    dispatch_async(dispatch_queue_create("com.MiddleWare.ChatCellModel.nameConverting", DISPATCH_QUEUE_SERIAL), ^{
        _chatTitleLatin = [_chatTitle convertedToLatin];
    });
}

- (NSString *)userID
{
    id userId = self.modelDictionary[@"userId"];
    return [userId isKindOfClass:[NSString class]] ? (NSString *)userId : nil;
}

- (NSString *)phone
{
    id phone = self.modelDictionary[@"phone"];
    return [phone isKindOfClass:[NSString class]] ? (NSString *)phone : nil;
}

- (NSString *)name
{
    id name = self.modelDictionary[@"name"];
    return [name isKindOfClass:[NSString class]] ? (NSString *)name : nil;
}

- (NSString *)description
{
    id description = self.modelDictionary[@"description"];
    return [description isKindOfClass:[NSString class]] ? (NSString *)description : nil;
}

- (NSString *)photoURLString
{
    id photo = self.modelDictionary[@"photo"];
    return [photo isKindOfClass:[NSString class]] ? (NSString *)photo : nil;
}

- (BOOL)isCompany
{
    id isCompany = self.modelDictionary[@"isCompany"];
    return [isCompany boolValue];
}

- (NSInteger)unreadCount
{
    return 0;
}

- (NSDate *)lastMessageTime
{
    return [NSDate date];
}

- (UIImage *)defaultImageWithSize:(CGSize)size rounded:(BOOL)rounded
{
    NSString * emoji = @"🛍";
    return [MWDefaultImageGenerator generateDefaultImageWithEmoji:emoji
                                                             size:size
                                                          rounded:rounded
                                              backgroundImageName:nil];
}

- (BOOL)isFavorite
{
    return NO;
}

- (BOOL)isEncrypted
{
    return NO;
}

- (BOOL)isCounterHidden
{
    return NO;
}

- (BOOL)isNotificationsHidden
{
    return NO;
}

@end