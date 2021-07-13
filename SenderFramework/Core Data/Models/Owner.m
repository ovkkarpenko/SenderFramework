//
//  Owner.m
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <SenderFramework/ParamsFacade.h>
#import "Owner.h"
#import "Contact.h"
#import "Dialog.h"
#import "Settings.h"
#import "SecGenerator.h"
#import "ParamsFacade.h"
#import "SenderFrameworkGlobals.h"
#import "NSURL+MW_PercentEscapes.h"
#import <SenderFramework/SenderFramework-Swift.h>

#define keychainKey [_ownerID stringByAppendingString: @"_encKey"]
#define appName [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]

@interface Owner ()
{
    BitcoinWallet * _mainWallet;
    NSString * _password;
}

@property (nonatomic, retain, readwrite) NSNumber * auth;
@property (nonatomic, retain) NSString * bwalletstate;

@end

@implementation Owner

@dynamic aid;
@dynamic auth;
@dynamic device;
@dynamic email;
@dynamic name;
@dynamic numberPhone;
@dynamic regDate;
@dynamic regionCode;
@dynamic syncContacts;
@dynamic syncDialogs;
@dynamic syncFavorits;
@dynamic uid;
@dynamic userImage;
@dynamic senderChatId;
@dynamic contacts;
@dynamic dialogs;
@dynamic settings;
@dynamic desc;
@dynamic ownimgurl;
@dynamic companies;
@dynamic publicKey;
@dynamic privateKey;
@dynamic sipLogin;
@dynamic bwalletstate;
@dynamic ownerID;
@dynamic mnemonic;
@dynamic localContacts;
@dynamic googleUser;
@dynamic authorizationTypeRaw;

@synthesize imRegistred, country, cName, cPrefix, imageURL = _imageURL;
@synthesize defaultImageEmoji = _defaultImageEmoji;

- (NSString *)getPhoneNumber
{
    if (self.numberPhone.length && [self.numberPhone characterAtIndex:0] != '+') {
        return [NSString stringWithFormat:@"+%@",self.numberPhone];
    }
    return self.numberPhone;
}

- (BOOL)imOperator
{
    return [self.companies length] > 0;
}

- (void)setOwnimgurl:(NSString *)ownimgurl
{
    [self willChangeValueForKey:@"ownimgurl"];
    [self setPrimitiveValue:ownimgurl forKey:@"ownimgurl"];
    _imageURL = nil;
    [self didChangeValueForKey:@"ownimgurl"];
}

- (NSURL *)imageURL
{
    if (!_imageURL)
    {
        if (self.ownimgurl)
            _imageURL = [NSURL mw_URLByAddingPercentEscapesToString:self.ownimgurl];
    }
    return _imageURL;
}

- (NSString *)defaultImageEmoji
{
    if (!_defaultImageEmoji)
        _defaultImageEmoji = [MWRandomEmojiGenerator generateRandomEmoji];
    return _defaultImageEmoji;
}

#pragma mark - Bitcoin

- (BitcoinWalletState)walletState
{
    if ([self.bwalletstate isEqualToString:@"ready"])
        return BitcoinWalletStateReady;
    else if ([self.bwalletstate isEqualToString:@"needSync"])
        return BitcoinWalletStateNeedSync;
    else if ([self.bwalletstate isEqualToString:@"empty"])
        return BitcoinWalletStateAbsent;
    else if ([self.bwalletstate isEqualToString:@"disabled"])
        return BitcoinWalletStateDisabled;
    else
        return BitcoinWalletStateUnknown;
}

-(void)setWalletState:(BitcoinWalletState)walletState
{
    switch (walletState) {
        case BitcoinWalletStateAbsent: {
            self.bwalletstate = @"empty";
            break;
        }
        case BitcoinWalletStateNeedSync: {
            self.bwalletstate = @"needSync";
            break;
        }
        case BitcoinWalletStateReady: {
            self.bwalletstate = @"ready";
            break;
        }
        case BitcoinWalletStateDisabled: {
            self.bwalletstate = @"disabled";
            break;
        }
        case BitcoinWalletStateUnknown: {
            self.bwalletstate = @"unknown";
            break;
        }
    }
}

-(void)setMnemonic:(NSString *)mnemonic
{
    [self willChangeValueForKey:@"mnemonic"];
    [self setPrimitiveValue:mnemonic forKey:@"mnemonic"];
    [self didChangeValueForKey:@"mnemonic"];
    _mainWallet = nil;
}

- (BOOL)isDefaultBitcoinPasswordUsed
{
    return [MnemonicConverter isDefaultWalletMnemonic:self.mnemonic];
}

- (BitcoinWallet *)getMainWallet:(NSError **)error
{
//    if (self.walletState != BitcoinWalletStateNeedSync)
//    {
        if (!_mainWallet)
        {
            NSString * encryptionKey = [self getPassword:error];
            if (encryptionKey)
            {
                _mainWallet = [BitcoinWallet walletWithEncryptedMnemonic:self.clearMnemonic
                                                                password:encryptionKey
                                             acceptDefaultWalletMnemonic:YES];
            }
            else
            {
                LLog(@"NO data saved in keychain!\n ");
            }
        }
        return _mainWallet;
//    }
//    else
//    {
//        *error = [NSError errorWithDomain:@"You need to sync your wallets before any operation" code:666 userInfo:nil];
//        return nil;
//    }
}

-(void)setMainWallet:(BitcoinWallet *)mainWallet
               error:(NSError **)error
     asDefaultWallet:(BOOL)flag
{
    NSString * encryptionKey = [self getPassword:error];
    if (encryptionKey)
    {
        self.mnemonic = [mainWallet encryptedMnemonicWithKey:encryptionKey isDefaultWallet:flag];
        _mainWallet = mainWallet;
    }
}

-(NSString *)mnemonicEncrypted
{
    return [_mainWallet encryptedMnemonicWithKey:[self getPassword:nil]];
}

- (NSString *)clearMnemonic
{
    return [MnemonicConverter deleteDefaultWalletAttributesFromMnemonic:self.mnemonic];
}

- (void)deleteMainWalletWithError:(NSError **)error
{
    NSError * deleteError;
    [self deletePasswordWithError:&deleteError];
    if (!deleteError)
        self.mnemonic = nil;

    if (error)
        *error = deleteError;
}

- (void)setRandomMainWallet:(NSError **)error asDefaultWallet:(BOOL)asDefaultWallet
{
    BitcoinWallet * newWallet = [BitcoinWallet walletWithRandomEntropy];
    [self setMainWallet:newWallet error:error asDefaultWallet:asDefaultWallet];
}

#pragma mark - Password Managing

- (NSString *)getPassword:(NSError **)error
{
    if (!_password)
        _password = [[SenderCore sharedCore].secureStorage passwordForService:appName account:self.ownerID error:error];
    return _password;
}

- (void)setPassword:(NSString *)password error:(NSError **)error isDefaultWalletPassword:(BOOL)flag
{
    BitcoinWallet * oldWallet = [BitcoinWallet walletWithEncryptedMnemonic:self.mnemonic
                                                                  password:_password
                                               acceptDefaultWalletMnemonic:YES];
    _password = nil;
    NSError * saveError;
    [[SenderCore sharedCore].secureStorage setPassword:password forService:appName account:self.ownerID error:&saveError];
    
    if (!saveError)
    {
        BitcoinWallet * walletToSave = oldWallet.mnemonic ? oldWallet : [self getMainWallet:&saveError];
        if (!saveError)
            self.mnemonic = [walletToSave encryptedMnemonicWithKey:password isDefaultWallet:flag];
    }
    
    if (error)
        *error = saveError;
}

- (void)deletePasswordWithError:(NSError **)error
{
    _password = nil;
    [[SenderCore sharedCore].secureStorage deletePasswordForService:appName account:self.ownerID error:error];
}

- (void)setGoogleAccount:(NSDictionary *)googleAcc
{
    self.googleUser = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:googleAcc];
}

- (NSDictionary *)getGoogleAccount
{
    return [[ParamsFacade sharedInstance] dictionaryFromNSData:self.googleUser];
}

#pragma mark - Authorization State

- (void)setAuthorizationState:(OwnerAuthorizationState)authorizationState
{
    NSNumber * authValue;

    switch (authorizationState)
    {
        case OwnerAuthorizationStateAuthorizedAsNewUser:
            authValue = @0;
            break;
        case OwnerAuthorizationStateAuthorized:
            authValue = @4;
            break;
        case OwnerAuthorizationStateSyncedWallet:
            authValue = @2;
            break;
        case OwnerAuthorizationStateSyncedChats:
            authValue = @5;
            break;
        case OwnerAuthorizationStateSyncedNotUsers:
            authValue = @6;
            break;
        case OwnerAuthorizationStateSyncedAll:
            authValue = @3;
            break;
        default:
            authValue = @99;
    }

    self.auth = authValue;
}

- (OwnerAuthorizationState)authorizationState
{
    if (!self.auth)
        return OwnerAuthorizationStateNotAuthorized;

    OwnerAuthorizationState authorizationState;

    switch ([self.auth integerValue])
    {
        case 0:
            authorizationState = OwnerAuthorizationStateAuthorizedAsNewUser;
            break;
        case 1:
        case 2:
            authorizationState = OwnerAuthorizationStateSyncedWallet;
            break;
        case 3:
            authorizationState = OwnerAuthorizationStateSyncedAll;
            break;
        case 4:
            authorizationState = OwnerAuthorizationStateAuthorized;
            break;
        case 5:
            authorizationState = OwnerAuthorizationStateSyncedChats;
            break;
        case 6:
            authorizationState = OwnerAuthorizationStateSyncedNotUsers;
            break;
        default:
            authorizationState = OwnerAuthorizationStateNotAuthorized;
            break;
    }

    return authorizationState;
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingAuthorizationState
{
    return [NSSet setWithObject:@"auth"];
}

#pragma mark - Authorization Type

- (OwnerAuthorizationType)authorizationType
{
    if (!self.authorizationTypeRaw) return OwnerAuthorizationTypeUndefined;
    return (OwnerAuthorizationType)self.authorizationTypeRaw.integerValue;
}

- (void)setAuthorizationType:(OwnerAuthorizationType)authorizationType
{
    self.authorizationTypeRaw = @(authorizationType);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingAuthorizationType
{
    return [NSSet setWithObject:@"authorizationTypeRaw"];
}

@end
