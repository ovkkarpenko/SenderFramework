//
//  SecGenerator.m
//  SENDER
//
//  Created by Eugene on 4/10/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "SecGenerator.h"

#include <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#include <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "SenderRequestBuilder.h"
#import "ServerFacade.h"
#import "NSData+base64.h"
#import <CoreBitcoin/BTCData.h>
#import "NS+BTCBase58.h"
#import "Owner.h"

static SecGenerator * encryptor;

@implementation SecGenerator

+ (SecGenerator *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        encryptor = [[SecGenerator alloc] init];
    });
    
    return encryptor;
}

- (NSString * _Nullable)hashedDeviceUDID
{
    NSString * deviceUDID = [[SenderCore sharedCore] configuration].deviceUDID;
    if (!deviceUDID) return nil;
    return [self hmac:deviceUDID withAlgoritm:SHA1_t];
}

- (NSString *)hmac:(NSString *)plainText withAlgoritm:(SCodeAlgoritm)aCode
{
    NSString * key = [SenderCore sharedCore].configuration.developerKey;
    return [self hmac:plainText withKey:key withAlgoritm:aCode];
}

- (NSString *)tempTokken
{
    if (!tempTokken || ![tempTokken isKindOfClass:[NSString class]])
        return @"";
    
    return tempTokken;
}

- (BOOL)recalculateTokenWithChalenge:(NSString *)challengeString
{
    NSString * aid = [[CoreDataFacade sharedInstance] getOwner].aid;
    
    if (!aid) {
        tempTokken = @"";
    }else {
        tempTokken = [self hmac:challengeString withKey:aid withAlgoritm:SHA256_t];
    }
    
    return YES;
}

- (NSString *)hmac:(NSString *)plainText withKey:(NSString *)key withAlgoritm:(SCodeAlgoritm)aCode
{
    NSData * HMACData;
    
    switch (aCode) {
        case SHA1_t:
            HMACData = [self stringToSha1:plainText withKey:key];
            break;
        case SHA256_t:
            HMACData = [self stringTo256:plainText withKey:key];
            break;
    }
   
    return HEXStringFromNSData(HMACData);
}

- (NSData *)stringToSha1:(NSString *)plainText withKey:(NSString *)key
{
    if (!plainText || !key) return [NSData new];
    const char * cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char * cData = [plainText cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}

- (NSData *)stringTo256:(NSString *)plainText withKey:(NSString *)key
{
    const char * cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char * cData = [plainText cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}

- (NSString *)appName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
}

#pragma mark - Generate random AES128 key

- (NSData *)generateSaltWithLenght:(int)saltLength {
    unsigned char salt[saltLength];
    for (int i=0; i<saltLength; i++) {
        salt[i] = (unsigned char)arc4random();
    }
    return [NSData dataWithBytes:salt length:saltLength];
}

- (NSData *)generateAES128Key
{
    return [self generateSaltWithLenght:kCCKeySizeAES128];
}

- (NSString *)generateTempKey
{
    NSData * keyData = [self generateSaltWithLenght:kCCKeySizeAES128];
    return [keyData base64EncodedStringWithOptions:0];
}

#pragma mark - User AES fuctions

- (NSData *)AESOperate:(CCOperation)operation cryptData:(NSData *)data key:(NSString *)key
{
    NSData * keyDD = [self convertPassToAES128KeyData:key];
    return [self encrypt:data key:keyDD iv:keyDD];
}

#pragma mark - Groupe Chats encr|decr

- (NSString *)encryptMessage:(NSString *)stringMessage withDialogKey:(NSData *)keyData
{
    NSData * messageData = [self encrypt:[stringMessage dataUsingEncoding:NSUTF8StringEncoding] key:keyData iv:nil];
    
    if (messageData)
        return  BTCBase58StringWithData(messageData);
    
    return nil;
}

- (NSString *)decryptMessage:(NSString *)stringMessage withDialogKey:(NSData *)keyData
{
    NSData * stringData = BTCDataFromBase58(stringMessage);
    
    if (!stringData)
        return nil;
    
    NSData * outData = [self decrypt:stringData key:keyData iv:nil];
    if (outData)
        return [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
    
    return nil;
}

- (NSString *)encodeKeyForExport:(NSString *)sourceString withKey:(NSString *)key
{
    NSData * keyDD = [self convertPassToAES128KeyData:key];
    
    NSData * keyData = [self encrypt:[sourceString dataUsingEncoding:NSUTF8StringEncoding] key:keyDD iv:nil];
    
    if (keyData)
        return  BTCBase58StringWithData(keyData);
    
    return nil;
}

- (NSString *)decodeKeyFromImportString:(NSString *)inputString withKey:(NSString *)key
{
    NSData * stringData = BTCDataFromBase58(inputString);
    
    if (!stringData)
        return nil;
    
    NSData * keyDD = [self convertPassToAES128KeyData:key];
    
    NSData * outData = [self decrypt:stringData key:keyDD iv:nil];
    if (outData)
        return [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
    
    return nil;
}

#pragma mark - PBKDF2 Derivation

- (NSData *)convertPassToAES128KeyData:(NSString *)saltKey
{
    NSData * myPassData = [saltKey dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData * salt = DataFromHEXString(@"4205c730b7afd0c048a9e9775ac4167e");
    int rounds = 1000;
    
    unsigned char dataBuffer[16];
    int res = CCKeyDerivationPBKDF(kCCPBKDF2, myPassData.bytes, myPassData.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA1, rounds, dataBuffer, 16);
    
    if (res < 0) {
        return nil;
    }
    
    NSData * resData = [[NSData alloc] initWithBytes:dataBuffer length:16];
    
    if (resData)
        return resData;
    
    return nil;
}

- (NSString *)convertPassToHexDecimalString:(NSString *)pass
{
    NSData * data = [self convertPassToAES128KeyData:pass];
    NSString * hexString = HEXStringFromNSData(data);
    
    if (hexString.length) {
        return [NSString stringWithString:hexString];
    }
    return nil;
}

#pragma mark - AES Encryption / Decryption

- (NSMutableData *) encrypt:(NSData*)data key:(NSData *)key iv:(NSData *)initializationVector
{
    return [self cryptData:data key:key iv:initializationVector operation:kCCEncrypt];
}

- (NSMutableData *) decrypt:(NSData *)data key:(NSData *)key iv:(NSData *)initializationVector
{
    return [self cryptData:data key:key iv:initializationVector operation:kCCDecrypt];
}

- (NSMutableData *) cryptData:(NSData *)data key:(NSData *)key iv:(NSData *)iv operation:(CCOperation)operation
{
    if (!data || !key) return nil;
 
    if (!iv) {
        iv = DataFromHEXString(@"01f01f01f01f01f01f01f01f01f01f01");
    }
    
    int blockSize = kCCBlockSizeAES128;
    int encryptedDataCapacity = (int)(data.length / blockSize + 1) * blockSize;
    NSMutableData * encryptedData = [[NSMutableData alloc] initWithLength:encryptedDataCapacity];

    if (iv.length == 0)
    {
        iv = nil;
    }
    
    if (iv) {
        if (iv.length >= blockSize) {

        }
        else {
            return nil;
        }
    }
    
    size_t dataOutMoved = 0;
    CCCryptorStatus cryptstatus = CCCrypt(
                                          operation,                   // CCOperation op,         /* kCCEncrypt, kCCDecrypt */
                                          kCCAlgorithmAES,             // CCAlgorithm alg,        /* kCCAlgorithmAES128, etc. */
                                          kCCOptionPKCS7Padding,       // CCOptions options,      /* kCCOptionPKCS7Padding, etc. */
                                          key.bytes,                   // const void *key,
                                          key.length,                  // size_t keyLength,
                                          iv ? iv.bytes : NULL,        // const void *iv,         /* optional initialization vector */
                                          data.bytes,                  // const void *dataIn,     /* optional per op and alg */
                                          data.length,                 // size_t dataInLength,
                                          encryptedData.mutableBytes,  // void *dataOut,          /* data RETURNED here */
                                          encryptedData.length,        // size_t dataOutAvailable,
                                          &dataOutMoved                // size_t *dataOutMoved
                                          );
    
    if (cryptstatus == kCCSuccess)
    {
        encryptedData.length = dataOutMoved;
        return encryptedData;
    }
    else {
        
        return nil;
        // какие то такие ошибки бывают
        //kCCSuccess          = 0,
        //kCCParamError       = -4300,
        //kCCBufferTooSmall   = -4301,
        //kCCMemoryFailure    = -4302,
        //kCCAlignmentError   = -4303,
        //kCCDecodeError      = -4304,
        //kCCUnimplemented    = -4305,
        //kCCOverflow         = -4306
    }
}

#pragma mark NSData <--> HEX

NSString * HEXStringFromNSData(NSData * data) {
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger dataLength  = [data length];
    NSMutableString * hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

NSData * DataFromHEXString(NSString * string) {
    
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = (int)string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

@end
