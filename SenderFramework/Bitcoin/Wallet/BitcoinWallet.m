//
//  BitcoinWallet.m
//  SENDER
//
//  Created by Roman Serga on 16/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "BitcoinWallet.h"
#import "NS+BTCBase58.h"
#import "NSData+BTCData.h"
#import "SecGenerator.h"

NSString *const privat24BitcoinPasswordPrefixVer1 = @"+++P24+++";
NSString *const privat24BitcoinPasswordPrefixVer2 = @"P24_DEF";

@implementation BTCBlockchainInfo (MarketPrice)

- (NSMutableURLRequest*)requestForMarketPrice
{
    NSString* urlString = @"https://blockchain.info/ticker";
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"GET";
    return request;
}

- (NSMutableURLRequest*) requestForUnspentOutputsWithExtendedPublicKeys:(NSArray*)exPubs
{
    if (exPubs.count == 0) return nil;
    
    NSString* urlString = [NSString stringWithFormat:@"https://blockchain.info/unspent?active=%@", [exPubs componentsJoinedByString:@"%7C"]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"GET";
    return request;
}

- (NSArray*) unspentOutputsWithExtendedPublicKeys:(NSArray<NSString *> *)exPubs error:(NSError**)errorOut
{
    NSURLRequest* req = [self requestForUnspentOutputsWithExtendedPublicKeys:exPubs];
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:errorOut];
    if (!data)
    {
        return nil;
    }
    return [self unspentOutputsForResponseData:data error:errorOut];
}

-(NSDictionary *)marketPrice:(NSError**)error
{
    NSURLRequest* req = [self requestForMarketPrice];
    NSURLResponse* response = nil;
    NSData* resultData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:error];
    
    if (!resultData) return nil;
    
    NSError* parseError;
    NSDictionary * result = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&parseError];
    
    return  result;
}

@end

@implementation BTCMnemonic (randomMnemonic)

+ (BTCMnemonic *)randomMnemonicWithPassword:(NSString *)password andWordListType:(BTCMnemonicWordListType)wordListType
{
    NSData * randomData;
    uint8_t randomBytes[16];
    NSUInteger bytesCount = sizeof(randomBytes) / sizeof(uint8_t);
    
    SecRandomCopyBytes(kSecRandomDefault, bytesCount, randomBytes);
    
    randomData = [NSData dataWithBytes:randomBytes length:bytesCount];
    
    return [[BTCMnemonic alloc]initWithEntropy:randomData password:password wordListType:wordListType];
}

@end

@implementation BitcoinWallet

@synthesize wordsString = _wordsString;

#pragma mark - Class methods

+(instancetype)walletWithRandomEntropy
{
    return [self walletWithRandomEntropyAndPassword:nil wordListType:BTCMnemonicWordListTypeEnglish];
}

+ (instancetype)walletWithRandomEntropyAndPassword:(NSString *)password wordListType:(BTCMnemonicWordListType)wordListType
{
    BTCMnemonic * mnemonic = [BTCMnemonic randomMnemonicWithPassword:password andWordListType:wordListType];
    return [self walletWithMnemonic:mnemonic];
}

+(instancetype)walletWithWords:(NSArray *)words password:(NSString *)password wordListType:(BTCMnemonicWordListType)wordListType
{
    BTCMnemonic * mnemonic = [[BTCMnemonic alloc]initWithWords:words password:password wordListType:wordListType];
    return [self walletWithMnemonic:mnemonic];
}

+(instancetype)walletWithData:(NSData *)data
{
    BTCMnemonic * mnemonic = [[BTCMnemonic alloc]initWithData:data];
    return [self walletWithMnemonic:mnemonic];
}

+(instancetype)walletWithEntropy:(NSData *)entropy password:(NSString *)password wordListType:(BTCMnemonicWordListType)wordListType
{
    BTCMnemonic * mnemonic = [[BTCMnemonic alloc]initWithEntropy:entropy password:password wordListType:wordListType];
    return  [self walletWithMnemonic:mnemonic];
}

+(instancetype)walletWithMnemonic:(BTCMnemonic *)mnemonic
{
    return [[self alloc]initWithMnemonic:mnemonic];
}

#pragma mark - Initializers

-(instancetype)initWithMnemonic:(BTCMnemonic *)mnemonic
{
    self = [super init];
    if (self)
    {
        _mnemonic = mnemonic;
    }
    return self;
}

#pragma mark - computed properties

-(NSString *)wordsString
{
    if (!_wordsString && self.mnemonic)
    {
        _wordsString = @"";
        for (NSUInteger index = 0; index < ([self.mnemonic.words count] - 1); index ++){
            NSString * word = self.mnemonic.words[index];
            _wordsString = [_wordsString stringByAppendingString:word];
            _wordsString = [_wordsString stringByAppendingString:@" "];
        }
        _wordsString = [_wordsString stringByAppendingString:[self.mnemonic.words lastObject]];
    }
    
    return _wordsString;
}

-(NSString *)extendedPublicKey
{
    return self.mnemonic.keychain.extendedPublicKey;
}

- (NSData *)extendedPublicKeyData
{
    return BTCDataFromBase58(self.mnemonic.keychain.extendedPublicKey);
}

- (NSString *)base58PublicKey
{
    return BTCBase58StringWithData(self.rootKey.compressedPublicKey);
}

-(NSString *)extendedPrivateKey
{
    return self.mnemonic.keychain.extendedPrivateKey;
}

- (NSData *)extendedPrivateKeyData
{
    return BTCDataFromBase58(self.mnemonic.keychain.extendedPrivateKey);
}

-(NSString *)balance
{
    return balanceFromUnspentTransactions(self.unspentOutputs);
}

-(NSData *)data
{
    return self.mnemonic.data;
}

-(BTCKey *)rootKey
{
    return [self.mnemonic.keychain derivedKeychainWithPath:@"m"].key;
}

-(NSString *)rootKeyPublic
{
    return self.rootKey.compressedPublicKeyAddress.string;
}

-(NSString *)rootKeyPrivate
{
    @synchronized(self) {
        return self.rootKey.privateKeyAddress.string;
    }
}

-(BTCAddress *)rootCompressedPublicKeyAddress
{
    return self.rootKey.compressedPublicKeyAddress;
}

-(BTCKey *)paymentKey
{
    return [self.paymentKeychain keyAtIndex:0];
}

-(BTCKeychain *)paymentKeychain
{
    return [self.mnemonic.keychain derivedKeychainWithPath:@"m/0'/0"];
}

#pragma mark - Implementation

-(BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[BitcoinWallet class]] && [self.mnemonic isEqual:[(BitcoinWallet *)object mnemonic]];
}

@end


@implementation BitcoinWallet (EncryptedMnemonics)

+ (instancetype)walletWithEncryptedMnemonic:(NSString *)mnemonic password:(NSString *)password
{
    return [self walletWithEncryptedMnemonic:mnemonic password:password acceptDefaultWalletMnemonic:NO];
}

+ (instancetype)walletWithEncryptedMnemonic:(NSString *)mnemonic
                                   password:(NSString *)password
                acceptDefaultWalletMnemonic:(BOOL)flag
{
    NSString * cleanMnemonic = flag ? [MnemonicConverter deleteDefaultWalletAttributesFromMnemonic:mnemonic] : mnemonic;
    NSString * mnemonicBase58 = [[NSString alloc]initWithData:BTCDataFromBase58(cleanMnemonic) encoding:NSUTF8StringEncoding];
    NSString * words = [[SecGenerator sharedInstance] decodeKeyFromImportString:mnemonicBase58 withKey:password];

    if (!words) {
        words = [[SecGenerator sharedInstance] decodeKeyFromImportString:cleanMnemonic withKey:password];
    }

    return [BitcoinWallet walletWithWords:[words componentsSeparatedByString:@" "] password:nil wordListType:BTCMnemonicWordListTypeEnglish];
}

- (NSString *)encryptedMnemonicWithKey:(NSString *)key
{
    return [self encryptedMnemonicWithKey:key isDefaultWallet:NO];
}

- (NSString *)encryptedMnemonicWithKey:(NSString *)key isDefaultWallet:(BOOL)flag
{
    NSString * wordsBase58;
    if (key)
        wordsBase58 = [[SecGenerator sharedInstance] encodeKeyForExport:self.wordsString withKey:key];

    if (flag)
        wordsBase58 = [MnemonicConverter mnemonicByAddingDefaultWalletAttributesToMnemonic:wordsBase58];

    return wordsBase58;
}

@end

@implementation MnemonicConverter

+ (BOOL)isUnsupportedDefaultWalletMnemonic:(NSString *)mnemonic
{
    return [mnemonic hasPrefix:privat24BitcoinPasswordPrefixVer1];
}

+ (BOOL)isDefaultWalletMnemonic:(NSString *)mnemonic
{
    BOOL isDefaultWalletMnemonic = NO;

    NSArray * defaultWalletPrefixes = @[privat24BitcoinPasswordPrefixVer1, privat24BitcoinPasswordPrefixVer2];

    for (NSString * prefix in defaultWalletPrefixes)
    {
        if ([mnemonic hasPrefix:prefix])
        {
            isDefaultWalletMnemonic = YES;
            break;
        }
    }

    return isDefaultWalletMnemonic;
}

+ (NSString *)deleteDefaultWalletAttributesFromMnemonic:(NSString *)defaultWalletMnemonic
{
    NSString * cleanMnemonic = defaultWalletMnemonic;

    NSArray * defaultWalletPrefixes = @[privat24BitcoinPasswordPrefixVer1, privat24BitcoinPasswordPrefixVer2];

    for (NSString * prefix in defaultWalletPrefixes)
    {
        NSRange prefixRange = [cleanMnemonic rangeOfString:prefix];
        if (prefixRange.location != NSNotFound)
            cleanMnemonic = [cleanMnemonic stringByReplacingCharactersInRange:prefixRange withString:@""];
    }

    return cleanMnemonic;
}

+ (NSString *)mnemonicByAddingDefaultWalletAttributesToMnemonic:(NSString *)mnemonic
{
    if ([self isDefaultWalletMnemonic:mnemonic])
        return mnemonic;
    else
        return [privat24BitcoinPasswordPrefixVer2 stringByAppendingString: mnemonic];
}

@end
