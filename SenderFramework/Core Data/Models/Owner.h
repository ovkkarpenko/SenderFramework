//
//  Owner.h
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BitcoinWallet.h"

typedef NS_ENUM(NSUInteger, BitcoinWalletState) {
    BitcoinWalletStateAbsent,
    BitcoinWalletStateNeedSync,
    BitcoinWalletStateReady,
    BitcoinWalletStateDisabled,
    BitcoinWalletStateUnknown
};

typedef NS_ENUM(NSUInteger, OwnerAuthorizationState) {
    OwnerAuthorizationStateNotAuthorized,
    OwnerAuthorizationStateAuthorizedAsNewUser,
    OwnerAuthorizationStateAuthorized,
    OwnerAuthorizationStateSyncedWallet,
    OwnerAuthorizationStateSyncedChats,
    OwnerAuthorizationStateSyncedNotUsers,
    OwnerAuthorizationStateSyncedAll
};

typedef NS_ENUM(NSUInteger, OwnerAuthorizationType) {
    OwnerAuthorizationTypeAnonymous,
    OwnerAuthorizationTypeSSO,
    OwnerAuthorizationTypeSender,
    OwnerAuthorizationTypeUndefined
};


@class Contact, Dialog, Settings;

@interface Owner : NSManagedObject

@property (nonatomic, retain) NSString * aid;

//Raw value of authorizationState. Use authorizationState instead of auth
@property (nonatomic, retain, readonly) NSNumber * auth;
@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * numberPhone;
@property (nonatomic, retain) NSString * regDate;
@property (nonatomic, retain) NSString * regionCode;
@property (nonatomic, retain) NSNumber * syncContacts;
@property (nonatomic, retain) NSNumber * syncDialogs;
@property (nonatomic, retain) NSNumber * syncFavorits;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * ownimgurl;
@property (nonatomic, retain) NSData * userImage;
@property (nonatomic, retain) NSData * googleUser;
@property (nonatomic, retain) NSString * senderChatId;
@property (nonatomic, retain) NSSet *contacts;
@property (nonatomic, retain) NSSet *dialogs;
@property (nonatomic, retain) Settings *settings;
@property (nonatomic, retain) NSNumber * imRegistred;
@property (nonatomic, retain) NSData * companies;
@property (nonatomic, retain) NSString * publicKey;
@property (nonatomic, retain) NSString * privateKey;
@property (nonatomic, retain) NSString * sipLogin;
@property (nonatomic, retain) NSString * ownerID;
@property (nonatomic, retain) NSString * mnemonic;
@property (nonatomic, retain) NSData * localContacts;

@property (nonnull, nonatomic, retain)  NSNumber *authorizationTypeRaw;


@property (nonatomic) BitcoinWalletState walletState;

@property (nonatomic) OwnerAuthorizationState authorizationState;
@property (nonatomic) OwnerAuthorizationType authorizationType;

@property (nonatomic, strong) NSString * country;
@property (nonatomic, strong) NSString * cName;
@property (nonatomic, strong) NSString * cPrefix;

@property (nonatomic, strong, readonly)  NSString * clearMnemonic;

@property (nonatomic, strong, readonly) NSURL * imageURL;
@property (nonatomic, strong, readonly) NSString * defaultImageEmoji;

- (NSString *)getPhoneNumber;
- (BOOL)imOperator;

- (BitcoinWallet *)getMainWallet:(NSError **)error;
- (void)setMainWallet:(BitcoinWallet *)mainWaller error:(NSError **)error asDefaultWallet:(BOOL)flag;
- (void)deleteMainWalletWithError:(NSError **)error;

- (void)setRandomMainWallet:(NSError **)error asDefaultWallet:(BOOL)asDefaultWallet;
- (NSString *)mnemonicEncrypted;

- (NSString *)getPassword:(NSError **)error;
- (void)setPassword:(NSString *)password error:(NSError **)error isDefaultWalletPassword:(BOOL)flag;
- (void)deletePasswordWithError:(NSError **)error;

- (void)setGoogleAccount:(NSDictionary *)googleAcc;
- (NSDictionary *)getGoogleAccount;

- (BOOL)isDefaultBitcoinPasswordUsed;

@end

@interface Owner (CoreDataGeneratedAccessors)

- (void)addContactsObject:(Contact *)value;
- (void)removeContactsObject:(Contact *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

- (void)addDialogsObject:(Dialog *)value;
- (void)removeDialogsObject:(Dialog *)value;
- (void)addDialogs:(NSSet *)values;
- (void)removeDialogs:(NSSet *)values;

@end
