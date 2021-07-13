//
// Created by Roman Serga on 5/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message;
@class Dialog;

extern NSString * const MWMessagesCryptographyEncryptionPublicKey;
extern NSString * const MWMessagesCryptographyEncryptionText;

@interface MWMessagesCryptography : NSObject

+ (NSString *)decryptedMessageTextOfMessage:(Message *)message inChat:(Dialog *)chat;
+ (NSDictionary *)encryptedMessageWithText:(NSString *)text chat:(Dialog *)chat;

/*
 * Returns nil if encryption was unsuccessful without changing the message.
 * Otherwise, changes message and returns it
 */
+ (Message *)encryptMessage:(Message *)message chat:(Dialog *)chat;

@end