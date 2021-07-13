//
//  Dialog.m
//  SENDER
//
//  Created by Roman Serga on 7/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <libPhoneNumber_iOS/NBPhoneNumberUtil.h>
#import <SenderFramework/SenderFramework.h>
#import <SenderFramework/SenderFramework-Swift.h>
#import "Dialog.h"
#import "Contact.h"
#import "Message.h"
#import "Owner.h"
#import "DialogSetting.h"
#import "CoreDataFacade.h"
#import <CoreBitcoin/BTCKey.h>
#import "ServerFacade.h"
#import "ParamsFacade.h"
#import "MessagesGap.h"
#import "ECCWorker.h"
#import "BarModel.h"
#import "ChatMember+CoreDataClass.h"
#import "Item.h"

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_sync(dispatch_get_main_queue(), block);\
        }
#endif

ChatType chatTypeFromString(NSString * string)
{
    if ([string isEqualToString:@"oper"])
        return ChatTypeOperator;
    else if ([string isEqualToString:@"group"])
        return ChatTypeGroup;
    else if ([string isEqualToString:@"p2p"])
        return ChatTypeP2P;
    else if ([string isEqualToString:@"company"])
        return ChatTypeCompany;
    else
        return ChatTypeUndefined;
};

NSString * stringFromChatType(ChatType chatType)
{
    NSString * chatTypeString;

    switch (chatType) {
        case ChatTypeOperator:
            chatTypeString = @"oper";
            break;
        case ChatTypeP2P:
            chatTypeString = @"p2p";
            break;
        case ChatTypeGroup:
            chatTypeString = @"group";
            break;
        case ChatTypeCompany:
            chatTypeString = @"company";
            break;
        case ChatTypeUndefined:
            chatTypeString = @"undefined";
            break;
    }

    return chatTypeString;
};

ChatState chatStateFromString(NSString * string)
{
    if ([string isEqualToString:@"normal"])
        return ChatStateNormal;
    else if ([string isEqualToString:@"saved"])
        return ChatStateSaved;
    else if ([string isEqualToString:@"removed"])
        return ChatStateRemoved;
    else if ([string isEqualToString:@"inactiveGroup"])
        return ChatStateInactive;
    else
        return ChatStateUndefined;
};

NSString * stringFromChatState(ChatState chatState)
{
    NSString * chatStateString;

    switch (chatState) {
        case ChatStateNormal:
            chatStateString = @"normal";
            break;
        case ChatStateSaved:
            chatStateString = @"saved";
            break;
        case ChatStateRemoved:
            chatStateString = @"removed";
            break;
        case ChatStateUndefined:
            chatStateString = @"undefined";
            break;
        case ChatStateInactive:
            chatStateString = @"inactiveGroup";
            break;
    }

    return chatStateString;
};

MessageStatus messageStatusFromString(NSString * string)
{
    if ([string isEqualToString:@"sent"])
        return MessageStatusSent;
    else if ([string isEqualToString:@"deliv"])
        return MessageStatusDelivered;
    else if ([string isEqualToString:@"read"])
        return MessageStatusRead;
    else
        return MessageStatusUnsent;
}

NSString * stringFromMessageStatus(MessageStatus messageStatus)
{
    NSString * messageStatusString;

    switch (messageStatus) {
        case MessageStatusUnsent:
            messageStatusString = @"fail";
            break;
        case MessageStatusSent:
            messageStatusString = @"sent";
            break;
        case MessageStatusDelivered:
            messageStatusString = @"deliv";
            break;
        case MessageStatusRead:
            messageStatusString = @"read";
            break;
    }

    return messageStatusString;
}

@interface Dialog ()
{
    Message * _lastMessageObject;
}

@property (nullable, nonatomic, retain, readwrite) NSString *type;
@property (nonnull, nonatomic, retain, readwrite)  NSNumber *state;
@property (nullable, nonatomic, retain, readwrite) NSString *lastMessageStatusRaw;

@end

@implementation Dialog

@synthesize p2pBTCKeyData, unsentText;
@synthesize parsedImageURL = _parsedImageURL;
@synthesize defaultImageEmoji = _defaultImageEmoji;

- (ChatType)chatType
{
    if (self.type)
        return chatTypeFromString(self.type);

    if ([self.p2p boolValue]) {
        return ChatTypeP2P;
    }

    if (!self.type)
    {
        if ([self.members count] > 1)
            return ChatTypeGroup;
        else
            return ChatTypeP2P;
    }

    return ChatTypeGroup;
}

- (void)setChatType:(ChatType)chatType
{
    self.type = stringFromChatType(chatType);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingChatType
{
    return [NSSet setWithObject:@"type"];
}

- (void)setChatState:(ChatState)chatState
{
    self.state = @(chatState);
}

- (ChatState)chatState
{
    if (!self.state)
        return ChatStateUndefined;
    else
        return (ChatState)[self.state integerValue];
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingChatState
{
    return [NSSet setWithObject:@"state"];
}

- (Message *)lastMessage
{
    if (!_lastMessageObject) [self updateLastMessage];
    return _lastMessageObject;
}

- (void)setGroupEncryptionState:(BOOL)isEncrypted
{
    if (self.isGroup)
        self.encrypted = @(isEncrypted);
}

- (BOOL)isEncrypted
{
    if (self.isP2P)
        return self.p2pBTCKeyData.length > 10;

    return [self.encrypted boolValue];
}

- (BOOL)hasSendBar
{
    return [self.sendBar.barItems count] > 0;
}

- (BOOL)isActive
{
    return !(self.isGroup && (self.chatState == ChatStateInactive || self.chatState == ChatStateRemoved));
}

- (BOOL)isP2P
{
    return self.chatType == ChatTypeP2P || self.chatType == ChatTypeCompany;
}

- (BOOL)isGroup
{
    return self.chatType == ChatTypeGroup;
}

- (BOOL)isSaved
{
    return self.chatState == ChatStateSaved;
}

- (NSArray *)getUnreadMessages
{
    return [[self.messages array] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K != %@", @"deliver", @"read"]];
}

- (NSArray *)getIncomingUnreadMessages
{
    NSPredicate * unreadPredicate = [NSPredicate predicateWithFormat:@"%K != %@ && %K != %@",
                                                                     @"deliver",
                                                                     @"read",
                                                                     @"fromId",
                                                                     [[CoreDataFacade sharedInstance] getOwner].uid];
    return [[self.messages array] filteredArrayUsingPredicate:unreadPredicate];
}

- (NSArray *)getMessagesWithStatus:(NSString *)status
{
    return [[self.messages array]filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K like %@", @"deliver", status]];
}

- (DialogSetting *)dialogSetting
{
    if (!self.chatSettings) {
        if ([[CoreDataFacade sharedInstance] checkForDialogSetting:self]) {
            return self.chatSettings;
        }
    }
    return self.chatSettings;
}

- (NSData *)p2pBTCKeyData
{
    return self.encryptionKey;
}

- (BOOL)isBlocked
{
    return [self.dialogSetting.blockChat boolValue];
}

- (void)setP2PEncryptionKey:(NSString *)encryptionKey
{
    if (self.isP2P)
    {
        NSData * keyData = BTCDataFromBase58(encryptionKey);
        self.encryptionKey = keyData;
    }
}

- (void)setGroupEncryptionKey:(NSString *)encryptionKey
                withSenderKey:(NSString *)senderKey
                     isOldKey:(BOOL)isOldKey
{
    if (self.isGroup)
    {
        if (encryptionKey.length)
        {
            if (senderKey.length)
            {
                NSData * keyData = BTCDataFromBase58(senderKey);

                NSString * chatKey = [[ECCWorker sharedWorker] eciesDecriptMEssage:encryptionKey
                                                                    withPubKeyData:keyData
                                                                         shortkEkm:YES
                                                                         usePubKey:NO];
                if (chatKey.length > 1)
                {
                    [self setGroupEncryptionKey:BTCDataFromBase58(chatKey) asOldKey:isOldKey];
                    if (!isOldKey)
                        self.encrypted = @(YES);
                }
                else if (!isOldKey)
                {
                    self.encrypted = @(NO);
                }
            }
        }
        else if (!isOldKey)
        {
            self.encrypted = @(NO);
        }
    }
}

- (void)setGroupEncryptionKey:(NSData *)newGroupKey asOldKey:(BOOL)oldKey
{
    if (!oldKey)
        self.encryptionKey = newGroupKey;

    NSMutableArray * listOfKeys;

    NSArray * oldArray = [[ParamsFacade sharedInstance] arrayFromNSData:self.oldGroupKeysData];
    if (oldArray.count)
        listOfKeys = [oldArray mutableCopy];
    else
        listOfKeys = [[NSMutableArray alloc] init];

    [listOfKeys addObject:newGroupKey];

    self.oldGroupKeysData = [[ParamsFacade sharedInstance] nSdateFromArray:listOfKeys];
}

- (NSArray *)oldGroupKeys
{
    return [[ParamsFacade sharedInstance] arrayFromNSData:self.oldGroupKeysData];
}

#pragma mark - Adding/Removing Messages

- (void)addMessages:(NSOrderedSet<Message *> *)values
{
    for (Message * message in values)
    {
        [self addMessagesObject:message];
    }
}

- (void)addMessagesObject:(Message *)value
{
    NSAssert(value.packetID != nil, @"Message packetID must not be nil!");

    id primitiveMessages = [self primitiveValueForKey:@"messages"];

    if ([primitiveMessages containsObject:value])
    {
        LLog(@"Dialog already contains message %@", value);
    }
    else
    {
        NSUInteger newIndex = [self indexInMessagesForNewObject:value];
        [primitiveMessages insertObject:value atIndex:newIndex];

        value.dialog = self;
        [self updateLastMessage];
    }

    if (!self.chatID)
        self.chatID = value.chat;
    if (!self.name)
        self.name = value.fromname;
}

- (void)fixPositionOfMessage:(Message *)message
{
    id messages = [self primitiveValueForKey:@"messages"];
    NSUInteger currentMessageIndex = [messages indexOfObject:message];
    if (currentMessageIndex != NSNotFound)
    {
        [messages removeObject:message];
        NSUInteger newMessageIndex = [self indexInMessagesForNewObject:message];
        [messages insertObject:message atIndex:newMessageIndex];
    }
}

- (void)updateLastMessage
{
    dispatch_main_sync_safe(^{
        NSPredicate * hasCreated = [NSPredicate predicateWithBlock:^BOOL(Message* msg, NSDictionary* bindings) {
            return msg.created != nil;
        }];
        NSComparator orderComparator = ^NSComparisonResult(Message *msg1, Message *msg2) {
            return [msg1.created compare:msg2.created];
        };
        NSOrderedSet * filteredMessages = [self.messages filteredOrderedSetUsingPredicate:hasCreated];
        NSArray * sortedMessages = [filteredMessages sortedArrayUsingComparator:orderComparator];
        _lastMessageObject = [sortedMessages lastObject];

        if (_lastMessageObject)
        {
            NSString * lastMessageText;
            if (!_lastMessageObject.isDeletedMessage)
            {
                lastMessageText = _lastMessageObject.previewText;
            }
            else
            {
                NSEnumerator * reversedEnumerator = [sortedMessages reverseObjectEnumerator];
                Message * message;
                while (lastMessageText == nil && (message = [reversedEnumerator nextObject])) {
                    if (!message.isDeletedMessage) lastMessageText = message.previewText;
                }
            }
            self.lastMessageText = lastMessageText;
            self.lastMessageTime = _lastMessageObject.created;
        }
    });
}

- (NSUInteger)indexInMessagesForNewObject:(Message *)object
{
    id messages = [self primitiveValueForKey:@"messages"];
    NSUInteger newMessageIndex = [messages indexOfObject:object
                                           inSortedRange:(NSRange) {0, [messages count]}
                                                 options:NSBinarySearchingInsertionIndex
                                         usingComparator:^NSComparisonResult(Message * msg1, Message * msg2) {
                                             if ([msg1.packetID integerValue] > [msg2.packetID integerValue])
                                                 return NSOrderedDescending;
                                             else if ([msg1.packetID integerValue] < [msg2.packetID integerValue])
                                                 return NSOrderedAscending;

                                             return NSOrderedSame;
                                         }];
    return newMessageIndex;
}

- (NSInteger)indexOfMessageWithPacketID:(NSInteger)packetID
{
    NSOrderedSet * allPacketIDs = [NSOrderedSet orderedSetWithArray:[[self.messages array] valueForKey:@"packetID"]];
    NSString * stringPacketID = [NSString stringWithFormat:@"%li", (long)packetID];

    NSInteger index;
    index = [allPacketIDs indexOfObject:stringPacketID];
    if (index == NSNotFound)
    {
        NSComparator comparator = ^NSComparisonResult(NSString * pid1, NSString * pid2) {

            if ([pid1 integerValue] > [pid2 integerValue])
                return NSOrderedDescending;
            else if ([pid1 integerValue] < [pid2 integerValue])
                return NSOrderedAscending;

            return NSOrderedSame;
        };

        index = [allPacketIDs indexOfObject:stringPacketID
                              inSortedRange:(NSRange) {0, [allPacketIDs count]}
                                    options:NSBinarySearchingInsertionIndex
                            usingComparator:comparator];
    }
    else {
        return packetID;
    }

    return index;
}

- (NSInteger)packetIDOfMessageAtIndex:(NSInteger)index
{
    NSString * packetID;
    if (index >= 0 && index < [self.messages count])
    {
        Message * message = self.messages[index];
        packetID = message.packetID;
    }
    return packetID != nil ? [packetID integerValue] : NSNotFound;
}

- (void)addGapsObject:(MessagesGap *)value
{
    for (MessagesGap * gap in self.gaps) {if ([value isIdenticalToGap:gap]) return;}

    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"gaps"
                withSetMutation:NSKeyValueUnionSetMutation
                   usingObjects:changedObjects];

    [[self primitiveValueForKey:@"gaps"] addObject:value];

    [self didChangeValueForKey:@"gaps"
               withSetMutation:NSKeyValueUnionSetMutation
                  usingObjects:changedObjects];
}

- (MessageStatus)lastMessageStatus
{
    return messageStatusFromString(self.lastMessageStatusRaw);
}

- (void)setLastMessageStatus:(MessageStatus)messageStatus
{
    self.lastMessageStatusRaw = stringFromMessageStatus(messageStatus);
}

- (void)setImageURL:(NSString *)imageURL
{
    [self willChangeValueForKey:@"imageURL"];
    [self setPrimitiveValue:imageURL forKey:@"imageURL"];
    _parsedImageURL = nil;
    [self didChangeValueForKey:@"imageURL"];
}

- (NSURL *)parsedImageURL
{
    if (!_parsedImageURL)
    {
        _parsedImageURL = [NSURL mw_URLByAddingPercentEscapesToString:self.imageURL];
    }
    return _parsedImageURL;
}

- (NSString *)defaultImageEmoji
{
    if (!_defaultImageEmoji)
    {
        switch (self.chatType)
        {
            case ChatTypeOperator:
            {
                _defaultImageEmoji = @"🙏";
            }
                break;
            case ChatTypeGroup:
            {
                _defaultImageEmoji = @"👥‍️";
            }
                break;
            case ChatTypeCompany:
            {
                _defaultImageEmoji = @"🛍";
            }
                break;
            default:
            {
                NSString * userID = userIDFromChatID(self.chatID);
                if (userID && [userID isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString])
                    _defaultImageEmoji = [[CoreDataFacade sharedInstance] getOwner].defaultImageEmoji;
                else
                    _defaultImageEmoji = [MWRandomEmojiGenerator generateRandomEmoji];
            }
                break;
        }
    }
    return _defaultImageEmoji;
}

- (void)addPhone:(NSString *)phone
{
    Item * new = (Item *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"Item"];
    new.value = phone;
    new.type = @"phone";
    [self addItemsObject:new];
}

- (Item *)getPhoneItem
{
    NSArray * itemsArray = [self.items allObjects];
    for (Item * item in itemsArray)
    {
        if ([item.type isEqualToString:@"phone"])
            return item;
    }
    return nil;
}

- (NSString *)getPhoneFormatted:(BOOL)formatted
{
    NSString * returnPhone = @"";

    Item * item = [self getPhoneItem];

    if(item.value)
    {
        returnPhone = item.value;

        if (formatted)
        {
            NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
            NSError *error = nil;
            NBPhoneNumber *myNumber;

            NSString * phone = [item.value hasPrefix:@"+"] ? item.value : [@"+" stringByAppendingString:item.value];
            myNumber = [phoneUtil parse:phone defaultRegion:@"UA" error:&error];

            if (error == nil)
                returnPhone = [phoneUtil format:myNumber numberFormat: NBEPhoneNumberFormatINTERNATIONAL error:&error];
        }
    }

    return returnPhone;
}

- (NSArray <Contact *> *)membersContacts
{
    NSMutableArray * membersContactsMutable = [NSMutableArray array];
    for (ChatMember * member in self.members) {
        [membersContactsMutable addObject:member.contact];
    }
    NSArray * membersContacts = [membersContactsMutable copy];
    return membersContacts;
}

@end
