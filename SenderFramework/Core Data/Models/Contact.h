//
//  Contact.h
//  SENDER
//
//  Created by Eugene Gilko on 9/10/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreBitcoin/BTCKey.h>

@class BarModel, Dialog, Item, Message, ChatMember;

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString * contactDescription;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * isOnline;
@property (nonatomic, retain) NSString * msgKey;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * bitcoinAddress;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * localID;
@property (nonatomic, retain) NSNumber * isCompany;

@property (nonatomic, retain) NSSet<Item *> * items;
@property (nonatomic, retain) NSSet<ChatMember *> * memberRepresentations;

@property (nonatomic, retain) Dialog * p2pChat;

//Not in DB

@property (nonatomic, retain) NSDate * lastOnlineCallTime;
@property (nonatomic, strong) UIColor * cellBackgroundColor;
@property (nonatomic, strong) NSArray * actions;

@property (nonatomic, strong, readonly, nullable) NSURL * parsedImageURL;
@property (nonatomic, strong, readonly, nonnull) NSString * defaultImageEmoji;

- (Item *)getSomeItem;

- (NSString *)getPhoneFormatted:(BOOL)formatted;

- (void)addPhone:(NSString *)phone;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addChatsObject:(Dialog *)value;
- (void)removeChatsObject:(Dialog *)value;
- (void)addChats:(NSSet *)values;
- (void)removeChats:(NSSet *)values;

- (void)addMemberRepresentationsObject:(ChatMember *)value;
- (void)removeMemberRepresentationsObject:(ChatMember *)value;
- (void)addMemberRepresentations:(NSSet *)values;
- (void)removeMemberRepresentations:(NSSet *)values;

- (void)addItemsObject:(Item *)value;
- (void)removeItemsObject:(Item *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
