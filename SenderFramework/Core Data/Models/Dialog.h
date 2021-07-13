//
//  Dialog.h
//  SENDER
//
//  Created by Roman Serga on 7/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, ChatType) {
    ChatTypeOperator = 0,
    ChatTypeGroup,
    ChatTypeP2P,
    ChatTypeCompany,
    ChatTypeUndefined
};

typedef NS_ENUM(NSInteger, ChatState) {
    ChatStateNormal = 0, //Usual chat
    ChatStateSaved, //Usual chat that saved to address book. Only for P2P chats
    ChatStateInactive, //Chat that is not deleted, but it's members doesn't include owner
    ChatStateRemoved, //Chat that must be deleted
    ChatStateUndefined //Chat that "waits" for chat info to determine its state
};

typedef NS_ENUM(NSInteger, MessageStatus) {
    MessageStatusUnsent = 0,
    MessageStatusSent,
    MessageStatusDelivered,
    MessageStatusRead
};

ChatType chatTypeFromString(NSString * string);
NSString * stringFromChatType(ChatType chatType);

ChatState chatStateFromString(NSString * string);
NSString * stringFromChatState(ChatState chatState);

MessageStatus messageStatusFromString(NSString * string);
NSString * stringFromMessageStatus(MessageStatus messageStatus);

@class Contact, Message, Owner, DialogSetting, BTCKey, MessagesGap, BarModel;

NS_ASSUME_NONNULL_BEGIN

@interface Dialog : NSManagedObject

@property (nonatomic, strong, nullable) NSData * p2pBTCKeyData;
@property (nonatomic, strong, nullable) NSString * unsentText;

@property (nonatomic) ChatType chatType;
@property (nonatomic) ChatState chatState;

@property (nonatomic, readonly) BOOL isP2P;
@property (nonatomic, readonly) BOOL isGroup;
@property (nonatomic, readonly) BOOL isSaved;
@property (nonatomic, readonly) BOOL hasSendBar;
@property (nonatomic, readonly) BOOL isActive;

@property (nonatomic, strong, readonly, nonnull) NSString * defaultImageEmoji;
@property (nonatomic, strong, readonly, nullable) NSURL * parsedImageURL;

/*
 * Returns last message in dialog, sorted by created.
 * Lazy property. Is was't called, calls updateLastMessage before returning.
 */
@property (nonatomic, readonly) Message * _Nullable lastMessage;
@property (nonatomic) MessageStatus lastMessageStatus;

- (NSArray *)oldGroupKeys;

- (void)setP2PEncryptionKey:(NSString * _Nullable)encryptionKey;

- (void)setGroupEncryptionKey:(NSString * _Nullable)encryptionKey
                withSenderKey:(NSString * _Nullable)senderKey
                     isOldKey:(BOOL)isOldKey;

- (DialogSetting * _Nonnull)dialogSetting;

- (void)setGroupEncryptionState:(BOOL)isEncrypted;

- (BOOL)isBlocked;
- (NSArray *)getIncomingUnreadMessages;

- (NSArray *)getUnreadMessages;
- (NSArray *)getMessagesWithStatus:(NSString *)status;

- (BOOL)isEncrypted;

- (void)addPhone:(NSString *)phone;
- (NSString *)getPhoneFormatted:(BOOL)formatted;

- (NSArray <Contact *> *)membersContacts;

/*
 * If message with packet ID is present in messages of dialog, returns its index.
 * Otherwise, returns possible index of the message with given packetID.
 * Note: if dialog contains more than one message with given packetID, returns index of first of them.
 */
- (NSInteger)indexOfMessageWithPacketID:(NSInteger)packetID;

/*
 * Returns packetID of message at given index. If dialog has not message at given index, returns NSNotFound.
 */
- (NSInteger)packetIDOfMessageAtIndex:(NSInteger)index;

/*
 * Changes position of message in messages of dialog.
 * Must be used after changing packetID of message.
 */
- (void)fixPositionOfMessage:(Message *)message;

/*
 * Updates last message, lastMessageText and lastMessageTime of dialog synchronously on main thread
 * Sorts messages by created, using [NSArray sortedArrayUsingComparator:];
 */
- (void)updateLastMessage;

@end

NS_ASSUME_NONNULL_END

#import "Dialog+CoreDataProperties.h"
