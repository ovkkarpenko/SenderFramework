//
//  ECCWorker.h
//  SENDER
//
//  Created by Eugene Gilko on 1/18/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCKey.h>

@interface ECCWorker : NSObject

+ (ECCWorker *)sharedWorker;

- (NSString *)encriptForMessaget:(NSString *)message
                withPubKey:(NSString *)compressedPublicKey;

- (NSString *)decriptMessage:(NSString *)message;

- (NSString *)eciesEncriptMEssage:(NSString *)originalString
                       withPubKey:(BTCKey *)recipientKey
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey;

- (NSString *)eciesEncriptMEssage:(NSString *)originalString
                   withPubKeyData:(NSData *)recipientKeyData
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey;

- (NSString *)eciesDecriptMEssage:(NSString *)originalString
                   withPubKeyData:(NSData *)senderKeyData
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey;

- (NSString *)eciesDecriptMEssage:(NSString *)originalString
                       withPubKey:(BTCKey *)senderKey
                        shortkEkm:(BOOL)useSHortkEkm
                        usePubKey:(BOOL)usePubKey;

- (NSString *)eciesEncriptMData:(NSData *)messageData
                     withPubKey:(BTCKey *)recipientKey
                      shortkEkm:(BOOL)useSHortkEkm
                      usePubKey:(BOOL)usePubKey;

@end
