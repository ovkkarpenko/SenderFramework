//
//  SenderCore.m
//  SENDER
//
//  Created by Valentin Dumareckii on 9/20/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "SenderCore.h"
#import "ServerFacade.h"
#import "CoreDataFacade.h"
#import "MailLoger.h"
#import "ServerFacade.h"
#import <sys/utsname.h>
#import "CheckAddressBookChanges.h"
#import "SenderRequestBuilder.h"
#import "CometController.h"
#import "SenderNotifications.h"
#import "CoreDataBaseManager.h"
#import "LogerDBController.h"
#import "LogEvent.h"
#import "SecGenerator.h"
#import "Settings.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import <objc/runtime.h>
#import "SenderConstants.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "UnreadMessagesCounter.h"
#import "MWLocationFacade.h"
#import "MWLastActiveChatCoordinator.h"
#import "SecureStorage.h"
#import "MWSenderAuthorizationFacade.h"

#ifdef SENDER_FRAMEWORK_USE_GOOGLE_MAPS
#import <GoogleMaps/GoogleMaps.h>
#endif

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_sync(dispatch_get_main_queue(), block);\
        }
#endif

@implementation SenderCoreConfiguration

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.serverAddress = @"https://senderapi.com";
        self.onlineKeyServerAddress = @"https://senderapi.com/online";
    }
    return self;
}

@end

@interface SenderCore ()
{
    CheckAddressBookChanges * abWorker;
    NSString * chatIDToGoAfterSync;
}

@property(nonatomic, copy, readwrite) NSString * pushToken;
@property(nonatomic, copy, readwrite) NSString * voipToken;

@property (nonatomic, strong) MWSenderAuthorizationFacade * authorizationFacade;

@end

@implementation SenderCore

+ (nonnull instancetype)sharedCore
{
    static SenderCore *sharedCore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCore = [[self alloc] init];
        sharedCore.stylePalette = [[SenderStylePalette alloc]init];
    });
    return sharedCore;
}

- (NSString *)senderVersion
{
    return @"10";
}

- (instancetype)initWithApplication:(UIApplication *)application
{
    self = [self init];
    if (self)
    {
        [self setUpWithApplication:application];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.secureStorage = [[SecureStorage alloc]init];
        self.interfaceUpdater = [[MainInterfaceUpdater alloc]init];
        self.bitcoinSyncManagerBuilder = [[BitcoinSyncManagerBuilder alloc] init];
        dispatch_main_sync_safe(^{
            [CoreDataFacade sharedInstance];
            [MWLocationFacade sharedInstance];
        });
    }
    return self;
}

- (void)setConfiguration:(SenderCoreConfiguration *)configuration
{
    _configuration = configuration;
    [GIDSignIn sharedInstance].clientID = _configuration.googleClientID;
#ifdef SENDER_FRAMEWORK_USE_GOOGLE_MAPS
    if (configuration.googleMapsApiKey) [GMSServices provideAPIKey:configuration.googleMapsApiKey];
#endif
}

- (void)setUpWithApplication:(UIApplication *)application
{
    self.application = application;
    self.window = application.delegate.window;

    [self prepareSenderBeforeShowingControllers];

    if ([self isAuthorized]) [[LogerDBController sharedCore] addLogEvent:@{@"event":@"appWasLaunch"}];

    [self subscribeForNotificationsOfApplication:self.application];

    self.isPaused = YES;
}

- (void)subscribeForNotificationsOfApplication:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveData)
                                                 name:UIApplicationWillTerminateNotification
                                               object:application];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveData)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:application];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveData)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:application];
}

-(void)setStylePalette:(SenderStylePalette *)stylePalette
{
    _stylePalette = stylePalette;
}

- (MWSenderAuthorizationFacade *)authorizationFacade
{
    if (!_authorizationFacade)
    {
        _authorizationFacade = [[MWSenderAuthorizationFacade alloc] init];
        _authorizationFacade.delegate = self;
    }
    return _authorizationFacade;
}

- (void)prepareSenderBeforeShowingControllers
{
    NSArray<Dialog *> * unreadChats = [[CoreDataFacade sharedInstance] getUnreadChats];
    self.unreadMessagesCounter = [[UnreadMessagesCounter alloc] initWithChats:unreadChats];
    [self.interfaceUpdater addUpdatesHandler:self.unreadMessagesCounter];

    self.lastActiveChatCoordinator = [[MWLastActiveChatCoordinator alloc]init];
    [self.interfaceUpdater addUpdatesHandler:self.lastActiveChatCoordinator];

    self.activeChatsCoordinator = [[ActiveChatsCoordinator alloc] init];
}

#pragma mark Google SignIn

- (void)initContactUpdate
{
    abWorker = [[CheckAddressBookChanges alloc] init];
    [abWorker checkLocalContactArchive];
}

- (NSString *)machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString * result = [NSString stringWithCString:systemInfo.machine
                                           encoding:NSUTF8StringEncoding];
    NSString * path = [SENDER_FRAMEWORK_BUNDLE pathForResource:@"DeviceList" ofType:@"plist"];
    NSDictionary * deviceNamesByCode = [[NSDictionary alloc]initWithContentsOfFile:path];

    NSString * deviceName = deviceNamesByCode[result];
    if (deviceName)
        return deviceName;
    else
        return result;
}

- (void)sendLogToServer
{
    // DISABLED! USE JUST FOR TEST!!!!!!!!!!!
    NSArray * logsArray = [[LogerDBController sharedCore] findAllWithName:@"LogEvent"
                                                                 sortedBy:@"eventtime"
                                                                ascending:YES
                                                            withPredicate:nil];

    if (logsArray.count) {

        NSMutableArray * eventsArray = [NSMutableArray new];

        for (LogEvent * evModel in logsArray) {
            NSData * evData = evModel.eventdata;
            NSDictionary * evDict = [[ParamsFacade sharedInstance] dictionaryFromNSData:evData];
            if (evDict)
                [eventsArray addObject:evDict[@"model"]];

            [[LogerDBController sharedCore] deleteManagedObject:evModel];
        }

        [[ServerFacade sharedInstance] sendLogToServer:@{@"eventsArray":eventsArray} requestHandler:nil];
    }
}

- (BOOL)checkMySipLogin
{
    if (![CoreDataFacade sharedInstance].owner.sipLogin) {
        NSDictionary * fr = [[ServerFacade sharedInstance] getUserDeviceInfo:nil];
        LLog(@"SIP LOGIN ----  %@", fr);
        if ([fr[@"code"] integerValue] == 0) {
            [CoreDataFacade sharedInstance].owner.sipLogin = fr[@"devs"][0][@"sipLogin"];
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)sendToken
{
    if (self.pushToken)
        [[ServerFacade sharedInstance] sendMyToken:self.pushToken andViopToken:self.voipToken];
}

- (void)pause
{
    [[LogerDBController sharedCore] addLogEvent:@{@"event":@"appWillEnterBackground"}];
    [self.window endEditing:YES];
    [CometController sharedInstance].isPaused = YES;
}

- (BOOL)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    LLog(@"PUSH INCOME %@", userInfo);

    if (![self isAuthorized]) {
        return NO;
    }

    if (application.applicationState == UIApplicationStateBackground)
    {
        if (userInfo[@"online_key"])
        {
            NSString * info = [NSString stringWithFormat:@"PUSH_ONLINE_KEY = %@",userInfo[@"online_key"]];

            [[LogerDBController sharedCore] addLogEvent:@{@"event":info}];

            [[CometController sharedInstance] createHTTPRequest:userInfo[@"online_key"]
                                              withRequestHandler:^(NSDictionary *response, NSError *error) {
                if (response && [userInfo[@"comet"] boolValue])
                {
                    [[CometController sharedInstance] startCometFromBackData:userInfo
                                                          withRequestHandler:^(UIBackgroundFetchResult result)
                    {
                        /*
                         * Perform additional save because applicationWillTerminate: may not be called.
                         */
                        dispatch_main_sync_safe(^{ [[CoreDataFacade sharedInstance] saveContext]; });
                        completionHandler(UIBackgroundFetchResultNewData);
                    }];
                }
                else
                {
                    completionHandler(UIBackgroundFetchResultNewData);
                }
            }];
        }
        else {
            [[CometController sharedInstance] startCometFromBackData:userInfo
                                                   withRequestHandler:^(UIBackgroundFetchResult result)
                                                   {
                                                       LLog(@"FINISH PUSH SEQ ========== %lu ", (unsigned long) result);
                                                       /*
                                                        * Perform additional save
                                                        * because applicationWillTerminate: may not be called.
                                                        */
                                                       dispatch_main_sync_safe(^{
                                                           [[CoreDataFacade sharedInstance] saveContext];
                                                       });
                                                       completionHandler(UIBackgroundFetchResultNewData);
                                                   }];
        }
        return YES;
    }
    else
    {
        BOOL result = userInfo[@"ci"] != nil;
        if (result)
            completionHandler(UIBackgroundFetchResultNoData);
        return result;
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [MWURLHandler application:application
                                open:url
                   sourceApplication:sourceApplication
                          annotation:annotation
                            senderUI:self.senderUI];
}

- (void)                application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
                  completionHandler:(void (^)())completionHandler
{
    [CometController sharedInstance].backgroundTransferCompletionHandler = completionHandler;
}

- (void)             pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                          forType:(PKPushType)type
{
    [[CometController sharedInstance] createHTTPRequest:@"online_key"
                                     withRequestHandler:^(NSDictionary *response, NSError *error) {
                                         
                                     }];
}

- (void)addLogToLoger:(NSString *)newLog
{
    //    if (enableLog) {
    //        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    //            [mailLoger addNewLogToLoger:(NSString *)newLog];
    //        });
    //    }
}

- (void)sendLogsToEmails
{
    //    [mailLoger writeMail];
}

- (BOOL)isInBackground
{
    return self.application.applicationState == UIApplicationStateBackground;
}

- (void)setAuthorizationNavigationController:(UINavigationController *)authorizationNavigationController
{
    self.authorizationFacade.navigationController = authorizationNavigationController;
    BOOL shouldResolveConflict = [[[CoreDataFacade sharedInstance] getOwner] walletState] == BitcoinWalletStateNeedSync;
    if (self.isAuthorized && shouldResolveConflict)
    {
        if (!authorizationNavigationController)
        {
            NSException *exception = [NSException exceptionWithName:@"Cannot resolve bitcoin conflict"
                                                             reason:@"authorizationNavigationController is nil"
                                                           userInfo:nil];
            [exception raise];
            return;
        }
        [[BitcoinConflictResolver shared] startConflictResolvingInRootViewController:authorizationNavigationController
                                                                            delegate:nil];
    }
}

- (UINavigationController *)authorizationNavigationController
{
    return self.authorizationFacade.navigationController;
}

- (void)resume
{
    [[CoreDataFacade sharedInstance] getOwner].senderChatId = @"user+sender";
    [ServerFacade sharedInstance].sid = [[CoreDataFacade sharedInstance] getOwner].aid;
    [CometController sharedInstance].isPaused = NO;

    NSString * systemLanguage = [[NSLocale preferredLanguages] firstObject];
    Settings * settings = [[CoreDataFacade sharedInstance] getOwner].settings;
    NSString * settingsLanguage = settings.language;
    if (systemLanguage != nil && ![systemLanguage isEqualToString:settingsLanguage])
    {
        [[ServerFacade sharedInstance] sendLocalization:systemLanguage
                                         withCompletion:^(NSDictionary *response, NSError *error) {
            if (response && !error) settings.language = systemLanguage;
        }];
    }

    if ([self isAuthorized])
    {
        [[MWLocationFacade sharedInstance] isLocationUsageAllowed:^(BOOL locationAllowed) {
            if ([DBSettings.location boolValue] && locationAllowed)
                [[MWLocationFacade sharedInstance].locationManager startUpdatingLocation];
        }];
    }
}

- (void)reset
{
    [self.authorizationFacade deauthorize];
}

- (BOOL)isAuthorized
{
    return [[CoreDataFacade sharedInstance] getOwner].authorizationState == OwnerAuthorizationStateAuthorized ||
            [[CoreDataFacade sharedInstance] getOwner].authorizationState == OwnerAuthorizationStateSyncedWallet ||
            [[CoreDataFacade sharedInstance] getOwner].authorizationState == OwnerAuthorizationStateSyncedChats ||
            [[CoreDataFacade sharedInstance] getOwner].authorizationState == OwnerAuthorizationStateSyncedNotUsers ||
            [self isSynchronized];
}

- (BOOL)isSynchronized
{
    return [[CoreDataFacade sharedInstance] getOwner].authorizationState == OwnerAuthorizationStateSyncedAll;
}

- (BOOL)isSynchronizationIsProgress
{
    return self.authorizationFacade.isSynchronizationInProgress;
}

- (BOOL)readLogState
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"LogMode"] boolValue];
}

- (void)logOnOff:(BOOL)mode
{
    [[NSUserDefaults standardUserDefaults] setObject:@(mode) forKey:@"LogMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)checkEnableLog
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"LogMode"] boolValue];
}

- (NSString *)clientVersion
{
    return NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
}

-(void)setFullVersionEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults]setBool:!enabled forKey:@"fullVersionDisabled"];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

-(BOOL)isFullVersionEnabled
{
    return ![[NSUserDefaults standardUserDefaults]boolForKey:@"fullVersionDisabled"];
}

- (BOOL)isBitcoinEnabled
{
    if (self.configuration.bitcoinMode == SenderBitcoinModeDisabled)
        return NO;
    else if (self.configuration.bitcoinMode == SenderBitcoinModeEnabled)
        return YES;
    else
        return [self isFullVersionEnabled];
}

- (void)setPushToken:(NSString *)pushToken voipToken:(NSString *)voipToken
{
    self.voipToken = voipToken;
    self.pushToken = pushToken;
    [self sendToken];
}

- (void)changeFullVersionState:(BOOL)state completion:(void (^ _Nullable)(NSError *nullable))completion
{
    if (self.isFullVersionEnabled == state)
    {
        NSString * domain = state ? @"Full version is already on" : @"Full version is already off";
        NSError * error = [NSError errorWithDomain:domain
                                              code:state ? 1 : 2
                                          userInfo:nil];
        if (completion) completion(error);
        return;
    }
    [[ServerFacade sharedInstance] changeFullVersionState:state
                                        completionHandler:^(NSDictionary *response, NSError *error)
                                        {
                                            if (error)
                                            {
                                                if (completion) completion(error);
                                                return;
                                            }

                                            if (state)
                                                [self turnOnFullVersion];
                                            else
                                                [self turnOffFullVersion];

                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidChangeFullVersionState
                                                                                                    object:self
                                                                                                  userInfo:nil];
                                            });

                                            if (self.isSynchronized)
                                                [self startSynchronization:nil];

                                            if (completion) completion(nil);
                                        }];
}

- (void)turnOnFullVersion
{
    [self setFullVersionEnabled:YES];
}

- (void)turnOffFullVersion
{
    [[CoreDataFacade sharedInstance] cleanFullVersionData];
    [self setFullVersionEnabled:NO];
}

- (void)setIsPaused:(BOOL)isPaused
{
    _isPaused = isPaused;

    if (_isPaused)
        [self pause];
    else
        [self resume];

    [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidChangeIsPausedState
                                                        object:self
                                                      userInfo:@{@"isPaused": @(_isPaused)}];
}

- (void)startFullAuthorization
{
    if (!self.authorizationNavigationController)
    {
        NSException * exception = [NSException exceptionWithName:@"Cannot start full authorization"
                                                          reason:@"authorizationNavigationController is nil"
                                                        userInfo:nil];
        [exception raise];
        return;
    }
    [self.authorizationFacade startFullAuthorization];
}

- (void)startSSOAuthorizationWithAuthToken:(NSString *)authToken
{
    [self.authorizationFacade startSSOAuthorizationWith:authToken];
}

-(void)startSynchronization:(NSError **)error
{
    if (!self.authorizationNavigationController && self.isBitcoinEnabled)
    {
        NSException * exception = [NSException exceptionWithName:@"Cannot start bitcoin synchronization"
                                                          reason:@"authorizationNavigationController is nil"
                                                        userInfo:nil];
        [exception raise];
        return;
    }
    [self.authorizationFacade synchronize:error isBitcoinEnabled:self.isBitcoinEnabled];
}

- (void)saveData
{
    [[CoreDataFacade sharedInstance] saveContext];
}

@end

@implementation SenderCore (InterfaceUpdating)

-(void)setInterfaceUpdater:(MainInterfaceUpdater *)interfaceUpdater
{
    objc_setAssociatedObject(self, @selector(interfaceUpdater), interfaceUpdater, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(MainInterfaceUpdater *)interfaceUpdater
{
    MainInterfaceUpdater * interfaceUpdater = objc_getAssociatedObject(self, @selector(interfaceUpdater));
    return interfaceUpdater;
}

@end

@interface SenderCore (MWSenderAuthorizationFacadeDelegate) <MWSenderAuthorizationFacadeDelegate>
@end

@implementation SenderCore (MWSenderAuthorizationFacadeDelegate)

- (void)senderAuthorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
     didPerformedRegistrationWith:(MWSenderRegistrationModel *)model
{
    [self setFullVersionEnabled:(model.applicationMode == MWSenderApplicationModeFull)];
}

- (void)authorizationFacadeDidFinishedAuthorization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    [self sendToken];
    [self prepareSenderBeforeShowingControllers];

    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFinishAuthorization:)])
        [self.authorizationDelegate senderCoreDidFinishAuthorization:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidFinishAuthorization
                                                        object:self
                                                      userInfo:nil];
}

- (void)authorizationFacadeDidFailedAuthorizationWithModel:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFailAuthorization:)])
        [self.authorizationDelegate senderCoreDidFailAuthorization:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidFailAuthorization object:self];
}

- (void)authorizationFacadeDidFinishedDeauthorization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    self.isPaused = YES;
    self.unreadMessagesCounter = [[UnreadMessagesCounter alloc]init];

    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFinishDeauthorization:)])
        [self.authorizationDelegate senderCoreDidFinishDeauthorization:self];

    [[NSNotificationCenter defaultCenter] postNotificationName: SenderCoreDidFinishDeauthorization object: self];
}

- (void)      authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
didFailedDeauthorizationWithError:(NSError *)error
{
    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFailDeauthorization:)])
        [self.authorizationDelegate senderCoreDidFailDeauthorization:self];

    [[NSNotificationCenter defaultCenter] postNotificationName: SenderCoreDidFailDeauthorization object: self];
}

- (void)authorizationFacadeWillStartSynchronization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreWillStartSynchronization:)])
        [self.authorizationDelegate senderCoreWillStartSynchronization:self];

    [[NSNotificationCenter defaultCenter] postNotificationName: SenderCoreWillStartSynchronization object: self];
}

- (void)authorizationFacadeDidFinishSynchronization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    NSDictionary * userInfo = @{};
    if (chatIDToGoAfterSync)
    {
        NSMutableDictionary * userInfoMutable = [userInfo mutableCopy];
        userInfoMutable[@"chatIDToOpen"] = chatIDToGoAfterSync;
        userInfo = [userInfoMutable copy];
        chatIDToGoAfterSync = nil;
    }

    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFinishSynchronization:userInfo:)])
         [self.authorizationDelegate senderCoreDidFinishSynchronization:self userInfo:userInfo];

    [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidFinishSynchronization object:self];
}

- (void)authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
didFailedSynchronizationWithError:(NSError *)error
{
    if ([self.authorizationDelegate respondsToSelector:@selector(senderCoreDidFailSynchronization:)])
        [self.authorizationDelegate senderCoreDidFailSynchronization:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:SenderCoreDidFailSynchronization object:self];
}

- (SenderAuthBitcoinPasswordAction)passwordActionForMnemonic:(NSString *)mnemonic
                                         authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    if ([self.authorizationDelegate respondsToSelector:@selector(passwordActionForRemoteMnemonic:senderCore:)])
        return [self.authorizationDelegate passwordActionForRemoteMnemonic:mnemonic senderCore:self];
    else
        return SenderAuthBitcoinPasswordActionUndefined;
}

- (NSString *)defaultWalletPasswordForAuthorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
{
    if ([self.authorizationDelegate respondsToSelector:@selector(defaultBitcoinWalletPasswordForSenderCore:)])
        return [self.authorizationDelegate defaultBitcoinWalletPasswordForSenderCore:self];
    else
        return nil;
}


@end
