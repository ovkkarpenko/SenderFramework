//
//  SenderCore.h
//  SENDER
//
//  Created by Valentin Dumareckii on 9/20/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PushKit/PushKit.h>
#import <SenderFramework/SenderStylePalette.h>
#import <SenderFramework/BitcoinSyncManagerBuilder.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

typedef NS_ENUM(NSInteger, SenderAuthBitcoinPasswordAction) {
    SenderAuthBitcoinPasswordActionUndefined = -1,
    SenderAuthBitcoinPasswordActionCreateNew,
    SenderAuthBitcoinPasswordActionCreateDefault,
    SenderAuthBitcoinPasswordActionSaveCurrent,
    SenderAuthBitcoinPasswordActionSaveCurrentAndSetDefaultPassword
};

typedef NS_ENUM(NSInteger, SenderBitcoinMode) {
    SenderBitcoinModeDisabled = -1,
    SenderBitcoinModeEnabled,
    SenderBitcoinModeFullVersion
};

@class SenderCore;

@protocol SenderAuthorizationDelegate <NSObject>

@optional

- (NSString *)defaultBitcoinWalletPasswordForSenderCore:(nonnull SenderCore *)senderCore;

/*
 * If delegate cannot find appropriate action for mnemonic, it should return SenderAuthBitcoinPasswordActionUndefined
 */
- (SenderAuthBitcoinPasswordAction)passwordActionForRemoteMnemonic:(NSString *)remoteMnemonic
                                                        senderCore:(nonnull SenderCore *)senderCore;

- (void)senderCoreDidFinishAuthorization:(SenderCore *)senderCore;
- (void)senderCoreDidFailAuthorization:(SenderCore *)senderCore;

- (void)senderCoreWillStartSynchronization:(SenderCore *)senderCore;
- (void)senderCoreDidFinishSynchronization:(SenderCore *)senderCore userInfo:(NSDictionary *)userInfo;
- (void)senderCoreDidFailSynchronization:(SenderCore *)senderCore;

- (void)senderCoreDidFinishDeauthorization:(SenderCore *)senderCore;
- (void)senderCoreDidFailDeauthorization:(SenderCore *)senderCore;

@end

@protocol SenderSecureStorage

@required

- (NSString *)passwordForService:(NSString *)serviceName
                         account:(NSString *)account
                           error:(NSError **)error;

- (BOOL)deletePasswordForService:(NSString *)serviceName
                         account:(NSString *)account
                           error:(NSError **)error;

- (BOOL)setPassword:(NSString *)password
         forService:(NSString *)serviceName
            account:(NSString *)account
              error:(NSError **)error;

@end

@interface SenderCoreConfiguration: NSObject

@property (nonatomic, strong) NSString * deviceUDID;
@property (nonatomic, strong) NSString * developerID;
@property (nonatomic, strong) NSString * developerKey;
@property (nonatomic, strong) NSString * companyID;
@property (nonatomic, strong) NSString * deviceIMEI;
@property (nonatomic, strong) NSString * apnsString;
@property (nonatomic, strong) NSString * googleClientID;
@property (nonatomic, strong) NSString * serverAddress;
@property (nonatomic, strong) NSString * onlineKeyServerAddress;
@property (nonatomic, strong) NSString * googleMapsApiKey;
@property (nonatomic) SenderBitcoinMode bitcoinMode;

@end

@protocol BitcoinConflictResolverDelegate;
@protocol SenderUIProtocol;

@class MainInterfaceUpdater;
@class MWLastActiveChatCoordinator;
@class ActiveChatsCoordinator;
@class UnreadMessagesCounter;

@interface SenderCore : NSObject <BitcoinConflictResolverDelegate>

@property (nonnull, nonatomic, strong, readonly) NSString * machineName;
@property (nonnull, nonatomic, strong, readonly) NSString * senderVersion;
@property (nonnull, nonatomic, strong, readonly) NSString * clientVersion;

@property (nonatomic, readonly) BOOL isInBackground;
@property (nonatomic, readonly) BOOL isFullVersionEnabled;
@property (nonatomic, readonly) BOOL isBitcoinEnabled;

@property (nonatomic, readonly) BOOL isAuthorized;
@property (nonatomic, readonly) BOOL isSynchronized;
@property (nonatomic, readonly) BOOL isSynchronizationIsProgress;

@property(nonatomic, copy, readonly) NSString * pushToken;
@property(nonatomic, copy, readonly) NSString * voipToken;

@property (nonnull, nonatomic, strong) id<SenderSecureStorage> secureStorage;
@property (nonnull, nonatomic, strong) MainInterfaceUpdater * interfaceUpdater;
@property (nonnull, nonatomic, strong) ActiveChatsCoordinator * activeChatsCoordinator;
@property (nonnull, nonatomic, strong) SenderStylePalette * stylePalette;

@property (nonatomic, strong) UnreadMessagesCounter * unreadMessagesCounter;
@property (nonatomic, strong) MWLastActiveChatCoordinator * lastActiveChatCoordinator;
@property (nonatomic, strong) BitcoinSyncManagerBuilder * bitcoinSyncManagerBuilder;

@property (nonatomic, strong) SenderCoreConfiguration * configuration;

@property (nonatomic, strong) UIApplication *application;
@property (nonatomic, strong) UIWindow * window;

@property (nonatomic, strong, nullable) id<SenderUIProtocol> senderUI;

@property (nonatomic, weak) id<SenderAuthorizationDelegate> authorizationDelegate;

@property (nonatomic) BOOL isPaused;

+ (nonnull instancetype)sharedCore;

- (void)setUpWithApplication:(UIApplication *)application;

/*
 * Navigation controller where authorization screens will be presented during full authorization/resetting
 * Bitcoin sync and conflict resolving screens also will be presented on authorizationNavigationController.
 */
@property (nonatomic, strong) UINavigationController * authorizationNavigationController;

/*
 * Authorize user in sender and perform synchronization.
 * If process is successfully finished, -senderCoreDidFinishSynchronization:userInfo: method of authorizationDelegate
 * will be called
 */
- (void)startFullAuthorization;
- (void)startSSOAuthorizationWithAuthToken:(NSString *)authToken;

/*
 * Pauses SenderCore and perform synchronization.
 * If SenderCore isn't authorized, method will return with error.
 */
-(void)startSynchronization:(NSError **)error;

/*
 * Deauthorizes user and deletes user's data from database
 */
- (void)reset;

- (BOOL)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (void)                application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
                  completionHandler:(void (^)())completionHandler;

- (void)             pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                          forType:(PKPushType)type;

- (void)setPushToken:(NSString *)pushToken voipToken:(NSString *)voipToken;

- (void)changeFullVersionState:(BOOL)state completion:(void (^ _Nullable)(NSError *nullable))completion;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

/*
 * Saves data to database
 */
- (void)saveData;

@end

#pragma clang diagnostic pop
