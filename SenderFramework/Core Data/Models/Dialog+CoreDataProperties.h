//
//  Dialog+CoreDataProperties.h
//  SENDER
//
//  Created by Roman Serga on 7/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Dialog.h"

@class CompanyCard;
@class ChatMember;
@class Item;

NS_ASSUME_NONNULL_BEGIN

@interface Dialog (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *chatID;
@property (nullable, nonatomic, retain) NSString *localID;
@property (nullable, nonatomic, retain) NSString *companyID;
@property (nullable, nonatomic, retain) NSSet<Item *> * items;
@property (nonnull, nonatomic, retain)  NSNumber *encrypted;
@property (nullable, nonatomic, retain) NSData *encryptionKey;
@property (nullable, nonatomic, retain) NSData *oldGroupKeysData;
@property (nullable, nonatomic, retain) NSString *imageURL;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *needSync;
@property (nullable, nonatomic, retain, readonly) NSString *type;
@property (nonnull, nonatomic, retain, readonly)  NSNumber *state;
@property (nonnull, nonatomic, retain)  NSNumber *unreadCount;
@property (nullable, nonatomic, retain) DialogSetting *chatSettings;
@property (nullable, nonatomic, retain) NSSet<ChatMember *> *members;
@property (nullable, nonatomic, retain) NSOrderedSet<Message *> *messages;
@property (nullable, nonatomic, retain) Owner *owner;
@property (nullable, nonatomic, retain) NSSet<MessagesGap *> *gaps;

@property (nullable, nonatomic, retain) NSDate *lastMessageTime;
@property (nullable, nonatomic, retain) NSString *lastMessageText;
@property (nullable, nonatomic, retain, readonly) NSString *lastMessageStatusRaw;

@property (nullable, nonatomic, retain) BarModel * sendBar;
@property (nullable, nonatomic, retain) BarModel * operatorSendBar;

@property (nullable, nonatomic, retain) Contact * p2pContact;

@property (nullable, nonatomic, retain) CompanyCard * companyCard;
@property (nullable, nonatomic, retain) NSSet<ChatMember *> *admins;

@property (nullable, nonatomic, retain) NSString *chatDescription DEPRECATED_ATTRIBUTE;
@property (nullable, nonatomic, retain) NSString *p2p DEPRECATED_ATTRIBUTE;

@end

@interface Dialog (CoreDataGeneratedAccessors)

- (void)addGapsObject:(MessagesGap *)value;
- (void)removeGapsObject:(MessagesGap *)value;
- (void)addGaps:(NSSet<MessagesGap *> *)value;
- (void)removeGaps:(NSSet<MessagesGap *> *)value;

- (void)addMembersObject:(ChatMember *)value;
- (void)removeMembersObject:(ChatMember *)value;
- (void)addMembers:(NSSet<ChatMember *> *)values;
- (void)removeMembers:(NSSet<ChatMember *> *)values;

- (void)addAdminsObject:(ChatMember *)value;
- (void)removeAdminsObject:(ChatMember *)value;
- (void)addAdmins:(NSSet<ChatMember *> *)values;
- (void)removeAdmins:(NSSet<ChatMember *> *)values;

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

/*
 * After adding messages all messages in dialog will be sorted ascending by packet_id
 */
- (void)addMessagesObject:(Message *)value;
- (void)addMessages:(NSOrderedSet<Message *> *)values;
- (void)removeObjectFromMessagesAtIndex:(NSUInteger)idx;
- (void)removeMessagesObject:(Message *)value;
- (void)removeMessages:(NSOrderedSet<Message *> *)values;

@end

NS_ASSUME_NONNULL_END
