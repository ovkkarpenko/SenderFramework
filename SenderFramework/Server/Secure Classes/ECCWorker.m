//
//  ECCWorker.m
//  SENDER
//
//  Created by Eugene Gilko on 1/18/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "ECCWorker.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "Owner.h"
#import "Contact.h"
#import "Dialog.h"

//Crypto
#import <CommonCrypto/CommonCrypto.h>
#import <CoreBitcoin/BTCMnemonic.h>
#import <CoreBitcoin/BTCData.h>
#import <CoreBitcoin/BTCBase58.h>
#import <CoreBitcoin/BTCKeychain.h>
#import <CoreBitcoin/BTCKey.h>
#import <CoreBitcoin/BTCBigNumber.h>
#import <CoreBitcoin/BTCCurvePoint.h>
#import <CoreBitcoin/BTCFancyEncryptedMessage.h>
#import <CoreBitcoin/BTCScript.h>
#import "NS+BTCBase58.h"
#import "NSData+BTCData.h"
#import "BTCEncryptedMessage.h"

static ECCWorker * worker;

@implementation ECCWorker

+ (ECCWorker *)sharedWorker {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        worker = [[ECCWorker alloc] init];
    });
    return worker;
}

#pragma mark - ECIES encription/decription with addons

- (NSString *)encriptForMessaget:(NSString *)message
                withPubKey:(NSString *)compressedPublicKey {
    
    NSData * compresedPublicKeyData = BTCDataFromBase58(compressedPublicKey);
    BTCKey * keyFromPub = [[BTCKey alloc] initWithPublicKey:compresedPublicKeyData];
    
    if (!keyFromPub) {
        return nil;
    }
    
    BTCFancyEncryptedMessage * msg = [[BTCFancyEncryptedMessage alloc] initWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    
    msg.difficultyTarget = 0x00FFFFFF;
    
    NSData * encryptedMsg = [msg encryptedDataWithKey:keyFromPub seed:BTCDataFromHex(@"corezoidforever")];
    
    return BTCBase58StringWithData(encryptedMsg);
}

- (NSString *)decriptMessage:(NSString *)message {
    
    NSData * decSourceData = BTCDataFromBase58(message);
    
    BTCFancyEncryptedMessage * receivedMsg = [[BTCFancyEncryptedMessage alloc] initWithEncryptedData:decSourceData];
    
    NSError * error = nil;
    
    BTCKey * key = [self ownerBTCKey];
    
    NSData * decryptedData = [receivedMsg decryptedDataWithKey:key error:&error];
    
    NSString * dString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    return dString;
}

#pragma mark - ECIES encription

- (NSString *)eciesEncriptMData:(NSData *)messageData
                       withPubKey:(BTCKey *)recipientKey
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey
{
    BTCEncryptedMessage * em = [[BTCEncryptedMessage alloc] init];
    em.senderKey = [self ownerBTCKey];
    em.recipientKey = recipientKey;
    
    NSData * ciphertext = [em encrypt:messageData shortkEkm:useSHortkEkm usePubKey:usePubKey];
    return BTCBase58StringWithData(ciphertext);
}

- (NSString *)eciesEncriptMEssage:(NSString *)originalString
                       withPubKey:(BTCKey *)recipientKey
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey
{
    BTCEncryptedMessage * em = [[BTCEncryptedMessage alloc] init];
    em.senderKey = [self ownerBTCKey];
    em.recipientKey = recipientKey;
    
    NSData * message = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData * ciphertext = [em encrypt:message shortkEkm:useSHortkEkm usePubKey:usePubKey];
    
    return BTCBase58StringWithData(ciphertext);
}

- (NSString *)eciesEncriptMEssage:(NSString *)originalString
                   withPubKeyData:(NSData *)recipientKeyData
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey
{
    BTCEncryptedMessage * em = [[BTCEncryptedMessage alloc] init];
    em.senderKey = [self ownerBTCKey];
    em.recipientKeyData = recipientKeyData;
    
    NSData * message = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData * ciphertext = [em encrypt:message shortkEkm:useSHortkEkm usePubKey:usePubKey];
    
    return BTCBase58StringWithData(ciphertext);
}

#pragma mark - ECIES decription

- (NSString *)eciesDecriptMEssage:(NSString *)originalString
                   withPubKeyData:(NSData *)senderKeyData
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey
{
    BTCEncryptedMessage * rer = [[BTCEncryptedMessage alloc] init];
    if (!usePubKey) {
        rer.senderKeyData = senderKeyData;
    }
    rer.recipientKey = [self ownerBTCKey];
    
    NSData * ciphertext = BTCDataFromBase58(originalString);
    NSData * plaintext = [rer decrypt:ciphertext shortkEkm:useSHortkEkm usePubKey:usePubKey];
    
    return [[NSString alloc] initWithData:plaintext encoding:NSUTF8StringEncoding];
}

- (NSString *)eciesDecriptMEssage:(NSString *)originalString
                       withPubKey:(BTCKey *)senderKey
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey
{
    BTCEncryptedMessage * rer = [[BTCEncryptedMessage alloc] init];
    if (!usePubKey) {
        rer.senderKey = senderKey;
    }
    rer.recipientKey = [self ownerBTCKey];
    
    NSData * ciphertext = BTCDataFromBase58(originalString);
    NSData * plaintext = [rer decrypt:ciphertext shortkEkm:useSHortkEkm usePubKey:usePubKey];
    
    return [[NSString alloc] initWithData:plaintext encoding:NSUTF8StringEncoding];
}

- (BTCKey *)ownerBTCKey
{
    return [[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil].rootKey;
}

@end
