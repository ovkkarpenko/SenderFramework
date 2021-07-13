//
//  BitcoinWallet.h
//  SENDER
//
//  Created by Roman Serga on 16/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCMnemonic.h>
#import <CoreBitcoin/BTCAddress.h>
#import <CoreBitcoin/BTCTransactionInput.h>
#import <CoreBitcoin/BTCTransactionOutput.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>
#import <SenderFramework/BitcoinUtils.h>
#import <CoreBitcoin/BTCTransaction.h>
#import <CoreBitcoin/BTCKey.h>
#import <CoreBitcoin/BTCKeychain.h>
#import <CoreBitcoin/BTCBase58.h>
#import <CoreBitcoin/BTCBlockchainInfo.h>

@interface BTCBlockchainInfo (MarketPrice)

- (NSDictionary *)marketPrice:(NSError**)error;
- (NSArray*) unspentOutputsWithExtendedPublicKeys:(NSArray<NSString *> *)exPubs error:(NSError**)errorOut;

@end

@interface BTCMnemonic (RandomMnemonic)

+ (BTCMnemonic *)randomMnemonicWithPassword:(NSString *)password andWordListType:(BTCMnemonicWordListType)wordListType;

@end

@interface BitcoinWallet : NSObject

+ (instancetype _Nonnull)walletWithRandomEntropy;

+ (instancetype)walletWithRandomEntropyAndPassword:(NSString *)password
                                      wordListType:(BTCMnemonicWordListType)wordListType;
+ (instancetype)walletWithMnemonic:(BTCMnemonic *)mnemonic;

+ (instancetype)walletWithWords:(NSArray*)words
                       password:(NSString*)password
                   wordListType:(BTCMnemonicWordListType)wordListType;

+ (instancetype)walletWithData:(NSData*)data;

@property (nonatomic, strong, readonly) NSString * wordsString;

@property (nonatomic, strong, readonly) NSString * extendedPublicKey;
@property (nonatomic, strong, readonly) NSData * extendedPublicKeyData;

@property (nonatomic, strong, readonly) NSString * extendedPrivateKey;
@property (nonatomic, strong, readonly) NSData * extendedPrivateKeyData;

@property (nonatomic, strong, readonly) NSString * base58PublicKey;

@property (nonatomic, strong, readonly) NSString * balance;

@property (nonatomic, strong, readonly) BTCMnemonic * mnemonic;
@property (nonatomic, strong, readonly) BTCKey * rootKey;

@property (nonatomic, strong, readonly) NSString * rootKeyPublic;
@property (nonatomic, strong, readonly) NSString * rootKeyPrivate;

@property (nonatomic, strong, readonly) BTCAddress * rootCompressedPublicKeyAddress;

@property (nonatomic, strong, readonly) BTCKey * paymentKey;
@property (nonatomic, strong, readonly) BTCKeychain * paymentKeychain;

@property (nonatomic, strong) NSArray<BTCTransactionOutput *> * unspentOutputs;

@property (nonatomic, strong) NSData * data;

@end

@interface BitcoinWallet (EncryptedMnemonics)

+ (instancetype)walletWithEncryptedMnemonic:(NSString *)mnemonic
                                   password:(NSString *)password
                acceptDefaultWalletMnemonic:(BOOL)flag;

- (NSString *)encryptedMnemonicWithKey:(NSString *)key;
- (NSString *)encryptedMnemonicWithKey:(NSString *)key isDefaultWallet:(BOOL)flag;

@end

@interface MnemonicConverter : NSObject

+ (BOOL)isUnsupportedDefaultWalletMnemonic:(NSString *)mnemonic;
+ (BOOL)isDefaultWalletMnemonic:(NSString *)mnemonic;
+ (NSString *)deleteDefaultWalletAttributesFromMnemonic:(NSString *)defaultWalletMnemonic;
+ (NSString *)mnemonicByAddingDefaultWalletAttributesToMnemonic:(NSString *)mnemonic;

@end
