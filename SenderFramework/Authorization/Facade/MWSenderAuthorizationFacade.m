//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWSenderAuthorizationFacade.h"
#import "Owner.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "SecGenerator.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface MWSenderAuthorizationFacade()  <MWSenderAuthorizationModuleDelegate,
                                           MWSynchronizationProcessDelegate,
                                           MWBitcoinSenderSynchronizationDefaultWalletLogicProtocol>
{
    BOOL _synchronizationInProgress;
    BOOL _isBitcoinEnabled;
}

@property (nonatomic, strong) NSString * authToken;

@property (nonatomic, strong) MWBitcoinSenderSynchronizationProcess * synchronizationProcess;
@property (nonatomic, strong) id<MWSenderAuthorizationModuleProtocol> authorizationModule;

@property (nonatomic) BOOL isSSOAuthorization;

@end


@implementation MWSenderAuthorizationFacade

- (void)startFullAuthorization
{
    self.authToken = nil;
    self.isSSOAuthorization = NO;
    [self startAuthorization];
}

- (void)startSSOAuthorizationWith:(NSString *)authToken
{
    self.authToken = authToken;
    self.isSSOAuthorization = YES;
    [self startAuthorization];
}

- (BOOL)isSynchronizationInProgress
{
    return _synchronizationInProgress;
}

- (void)startAuthorization
{
    OwnerAuthorizationState authorizationState = [[[CoreDataFacade sharedInstance] getOwner] authorizationState];

    if ([[CoreDataFacade sharedInstance] getOwner].aid)
        [ServerFacade sharedInstance].sid = [[CoreDataFacade sharedInstance] getOwner].aid;
    else
        authorizationState = OwnerAuthorizationStateNotAuthorized;

    switch (authorizationState)
    {
        case OwnerAuthorizationStateNotAuthorized:
        case OwnerAuthorizationStateAuthorizedAsNewUser:
            [self startAuthorizationWithState:authorizationState];
            break;
        default:
            break;
    }
}

- (void)startAuthorizationWithState:(OwnerAuthorizationState)authorizationState
{
    NSString * udid = [[SecGenerator sharedInstance] hashedDeviceUDID];
    NSString * developerID = [SenderCore sharedCore].configuration.developerID;
    MWSenderAuthorizationModel * authorizationModel = [[MWSenderAuthorizationModel alloc] initWithDeviceUDID:udid
                                                                                                 developerID:developerID];
    authorizationModel.companyID = [SenderCore sharedCore].configuration.companyID;
    authorizationModel.deviceIMEI = [SenderCore sharedCore].configuration.deviceIMEI;
    authorizationModel.authToken = self.authToken;

    if (authorizationState == OwnerAuthorizationStateAuthorizedAsNewUser)
    {
        MWSenderFullAuthorizationModule * fullAuthorizationModule = [[MWSenderFullAuthorizationModule alloc] initWithNavigationController:self.navigationController
                                                                                                                                 delegate:self];
        [fullAuthorizationModule startEnteringName];
        self.authorizationModule = fullAuthorizationModule;
    }
    else
    {
        if (self.isSSOAuthorization)
            self.authorizationModule = [[MWSenderSSOAuthorizationModule alloc] initWithDelegate:self];
        else
            self.authorizationModule = [[MWSenderFullAuthorizationModule alloc] initWithNavigationController:self.navigationController
                                                                                                    delegate:self];
        [self.authorizationModule startAuthorizationWithModel:authorizationModel];
    }
}

- (void)deauthorize
{
    NSString * udid = [[SecGenerator sharedInstance] hashedDeviceUDID];
    NSString * developerID = [SenderCore sharedCore].configuration.developerID;
    MWSenderDeauthorizationModel * deauthorizationModel = [[MWSenderDeauthorizationModel alloc] initWithDeviceUDID:udid
                                                                                                       developerID:developerID];
    deauthorizationModel.companyID = [SenderCore sharedCore].configuration.companyID;
    deauthorizationModel.deviceIMEI = [SenderCore sharedCore].configuration.deviceIMEI;

    if ([[[CoreDataFacade sharedInstance] getOwner] authorizationType] == OwnerAuthorizationTypeSender)
    {
        self.authorizationModule = [[MWSenderFullAuthorizationModule alloc] initWithNavigationController:self.navigationController
                                                                                                delegate:self];
    }
    else
    {
        self.authorizationModule = [[MWSenderSSOAuthorizationModule alloc] initWithDelegate:self];
    }

    [self.authorizationModule deauthorizeWithModel:deauthorizationModel];
}

MWSynchronizationProcessState* synchronizationStateForOwnerState(OwnerAuthorizationState ownerState)
{
    switch (ownerState)
    {
        case OwnerAuthorizationStateNotAuthorized:
        case OwnerAuthorizationStateAuthorizedAsNewUser:
        case OwnerAuthorizationStateAuthorized:
            return MWSynchronizationProcessState.none;
        case OwnerAuthorizationStateSyncedWallet:
            return MWSynchronizationProcessState.syncingBitcoin;
        case OwnerAuthorizationStateSyncedChats:
            return MWSynchronizationProcessState.syncingChats;
        case OwnerAuthorizationStateSyncedNotUsers:
            return MWSynchronizationProcessState.syncingNotUsers;
        case OwnerAuthorizationStateSyncedAll:
            return MWSynchronizationProcessState.syncingCompanyCards;
    }
}

- (MWAbstractSynchronizationProcess *)createSynchronizationProcess
{
    MWAbstractSynchronizationProcess * synchronizationProcess;

    MWSenderSynchronizationProcessStorage * storage = [[MWSenderSynchronizationProcessStorage alloc]init];
    MWSynchronizationManager * synchronizationManager = [MWSynchronizationManager buildDefaultSynchronizationManager];

    if (_isBitcoinEnabled)
    {
        BitcoinSyncManager * bitcoinSyncManager = [[SenderCore sharedCore].bitcoinSyncManagerBuilder syncManagerWithRootViewController:self.navigationController
                                                                                                                              delegate:self];
        MWBitcoinSenderSynchronizationProcessStorage * bitcoinStorage = [[MWBitcoinSenderSynchronizationProcessStorage alloc] init];
        MWBitcoinSenderSynchronizationProcess * bitcoinSynchronizationProcess = [[MWBitcoinSenderSynchronizationProcess alloc] initWithBitcoinSyncManager:bitcoinSyncManager
                                                                                                                                           bitcoinStorage:bitcoinStorage
                                                                                                                                   synchronizationManager:synchronizationManager
                                                                                                                                                  storage:storage];
        bitcoinSynchronizationProcess.defaultWalletLogic = self;
        synchronizationProcess = bitcoinSynchronizationProcess;
    }
    else
    {
        synchronizationProcess = [[MWSenderSynchronizationProcess alloc] initWithSynchronizationManager:synchronizationManager
                                                                                                storage:storage];
    }
    return synchronizationProcess;
}

- (void)startSynchronizationWithState:(OwnerAuthorizationState)authorizationState
{
    if ([self.delegate respondsToSelector:@selector(authorizationFacadeWillStartSynchronization:)])
        [self.delegate authorizationFacadeWillStartSynchronization:self];

    _synchronizationInProgress = YES;

    self.synchronizationProcess = [self createSynchronizationProcess];
    self.synchronizationProcess.delegate = self;

    MWSynchronizationProcessState * savedState = synchronizationStateForOwnerState(authorizationState);
    NSError * error;
    MWSynchronizationProcessState * newState = [self.synchronizationProcess nextStateAfterState:savedState
                                                                                          error:&error];
    if (!error)
        self.synchronizationProcess.state = newState;
    [self.synchronizationProcess startSynchronization];
}

- (void)synchronize:(NSError **)error isBitcoinEnabled:(BOOL)isBitcoinEnabled
{
    if (![self checkAuthorizationStateForSynchronization:error])
        return;
    _isBitcoinEnabled = isBitcoinEnabled;
    [[CoreDataFacade sharedInstance] getOwner].authorizationState = OwnerAuthorizationStateAuthorized;
    [self startSynchronizationWithState:[[CoreDataFacade sharedInstance] getOwner].authorizationState];
}

- (BOOL)checkAuthorizationStateForSynchronization:(NSError **)error
{
    OwnerAuthorizationState currentState = [[CoreDataFacade sharedInstance] getOwner].authorizationState;
    if (currentState == OwnerAuthorizationStateNotAuthorized ||
            currentState ==  OwnerAuthorizationStateAuthorizedAsNewUser)
    {
        NSError * cannotSyncError = [NSError errorWithDomain:@"Cannot synchronize unauthorized user"
                                                        code:666
                                                    userInfo:nil];
        if (error)
            *error = cannotSyncError;
        return NO;
    }
    return YES;
}

- (void)senderAuthorizationPresenter:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
        didPerformedRegistrationWith:(MWSenderRegistrationModel *)model
{
    NSString * udid = [[SecGenerator sharedInstance] hashedDeviceUDID];
    NSString *hmac = [udid stringByAppendingString:model.deviceKey];
    NSString *aid = [[SecGenerator sharedInstance] hmac:hmac withAlgoritm:SHA256_t];

    OwnerAuthorizationType authorizationType = OwnerAuthorizationTypeUndefined;

    switch (model.authorizationType)
    {
        case MWSenderAuthorizationTypeAuth: authorizationType = OwnerAuthorizationTypeSender;
        case MWSenderAuthorizationTypeSso: authorizationType = OwnerAuthorizationTypeSSO;
        case MWSenderAuthorizationTypeAnonymous: authorizationType = OwnerAuthorizationTypeAnonymous;
    }

    [[CoreDataFacade sharedInstance] getOwner].authorizationType = authorizationType;
    [[CoreDataFacade sharedInstance] getOwner].aid = aid;

    if (![[CoreDataFacade sharedInstance] getOwner].senderChatId)
        [[CoreDataFacade sharedInstance] getOwner].senderChatId = @"user+sender";

    if ([self.delegate respondsToSelector:@selector(senderAuthorizationFacade:didPerformedRegistrationWith:)])
        [self.delegate senderAuthorizationFacade:self didPerformedRegistrationWith:model];
}

- (void)senderAuthorizationPresenter:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
     didAuthorizedAsNewUserWithModel:(MWSenderAuthorizationStepModel *)model
{
    [[CoreDataFacade sharedInstance] getOwner].authorizationState = OwnerAuthorizationStateAuthorizedAsNewUser;
}

- (void)senderAuthorizationPresenter:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
   didFinishedAuthorizationWithModel:(MWSenderAuthorizationStepModel *)model
{
    if ([model.additionalData[@"isSenderAuthorization"] boolValue])
        [[CoreDataFacade sharedInstance] getOwner].authorizationType = OwnerAuthorizationTypeSender;

    [ServerFacade sharedInstance].sid = [[CoreDataFacade sharedInstance] getOwner].aid;
    [[CoreDataFacade sharedInstance] getOwner].authorizationState = OwnerAuthorizationStateAuthorized;

    if ([self.delegate respondsToSelector:@selector(authorizationFacadeDidFinishedAuthorization:)])
        [self.delegate authorizationFacadeDidFinishedAuthorization:self];
}

- (void)senderAuthorizationPresenter:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
     didFailedAuthorizationWithModel:(MWSenderAuthorizationStepModel *)model
{
    [[CoreDataFacade sharedInstance] getOwner].authorizationState = OwnerAuthorizationStateNotAuthorized;

    if ([self.delegate respondsToSelector:@selector(authorizationFacadeDidFailedAuthorizationWithModel:)])
        [self.delegate authorizationFacadeDidFailedAuthorizationWithModel:self];
}

- (void)senderAuthorizationPresenterDidFinishedDeauthorization:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
{
    [[CoreDataFacade sharedInstance] clearOwnerModel];
    [[ServerFacade sharedInstance] sendMyToken:@"" andViopToken:@""];

    [ServerFacade sharedInstance].sid = nil;

    [[CoreDataFacade sharedInstance] saveContext];

    if ([self.delegate respondsToSelector:@selector(authorizationFacadeDidFinishedDeauthorization:)])
        [self.delegate authorizationFacadeDidFinishedDeauthorization:self];
}

- (void)senderAuthorizationPresenter:(id<MWSenderAuthorizationPresenterProtocol>)senderAuthorizationPresenter
   didFailedDeauthorizationWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(authorizationFacade:didFailedDeauthorizationWithError:)])
        [self.delegate authorizationFacade:self didFailedDeauthorizationWithError:error];
}
- (void)senderSynchronizationProcessDidFinishSynchronization:(MWAbstractSynchronizationProcess *)synchronizationProcess
{
    _synchronizationInProgress = NO;
    [[CoreDataFacade sharedInstance] getOwner].authorizationState = OwnerAuthorizationStateSyncedAll;
    [[CoreDataFacade sharedInstance] saveContext];

    if ([self.delegate respondsToSelector:@selector(authorizationFacadeDidFinishSynchronization:)])
        [self.delegate authorizationFacadeDidFinishSynchronization:self];
}

- (void)senderSynchronizationProcess:(MWAbstractSynchronizationProcess *)synchronizationProcess
   didFailedSynchronizationWithError:(NSError *)error
{
    _synchronizationInProgress = NO;
    if ([self.delegate respondsToSelector:@selector(authorizationFacade:didFailedSynchronizationWithError:)])
        [self.delegate authorizationFacade:self didFailedSynchronizationWithError:error];
}

- (SenderAuthBitcoinPasswordAction)passwordActionForWithMnemonic:(NSString *)mnemonic
{
    if ([self.delegate respondsToSelector:@selector(passwordActionForMnemonic:authorizationFacade:)])
        return [self.delegate passwordActionForMnemonic:mnemonic authorizationFacade:self];
    else
        return SenderAuthBitcoinPasswordActionUndefined;
}

- (NSString *)defaultWalletPasswordForWithSynchronizationProcess:(MWBitcoinSenderSynchronizationProcess *)synchronizationProcess
{
    if ([self.delegate respondsToSelector:@selector(defaultWalletPasswordForAuthorizationFacade:)])
        return [self.delegate defaultWalletPasswordForAuthorizationFacade:self];
    else
        return nil;
}

@end
