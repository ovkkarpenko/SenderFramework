//
//  SecGenerator.h
//  SENDER
//
//  Created by Eugene on 4/10/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

typedef NS_ENUM(NSInteger, SCodeAlgoritm) {
    SHA256_t = 0,
    SHA1_t
};

@interface SecGenerator : NSObject
{
    NSString * udid;
    NSString * tempTokken;
}

+ (SecGenerator *)sharedInstance;

- (NSString * _Nullable)hashedDeviceUDID;

- (NSString *)hmac:(NSString *)plainText withAlgoritm:(SCodeAlgoritm)aCode;
- (NSString *)hmac:(NSString *)plainText withKey:(NSString *)key withAlgoritm:(SCodeAlgoritm)aCode;
- (NSString *)tempTokken;
- (BOOL)recalculateTokenWithChalenge:(NSString *)challengeString;
- (NSString *)generateTempKey;
- (NSData *)generateAES128Key;
// enc\dec pass key
- (NSString *)encodeKeyForExport:(NSString *)sourceString withKey:(NSString *)key;
- (NSString *)decodeKeyFromImportString:(NSString *)inputString withKey:(NSString *)key;

- (NSData *)AESOperate:(uint32_t)operation cryptData:(NSData *)data key:(NSString *)key;

- (NSString *)encryptMessage:(NSString *)stringMessage withDialogKey:(NSData *)keyData;
- (NSString *)decryptMessage:(NSString *)stringMessage withDialogKey:(NSData *)keyData;

@end
