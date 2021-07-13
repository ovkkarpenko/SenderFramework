//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenderFramework/SenderCore.h>

@class MWSenderAuthorizationFacade;
@class MWSenderRegistrationModel;

@protocol MWSenderAuthorizationFacadeDelegate <NSObject>

- (void)senderAuthorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
        didPerformedRegistrationWith:(MWSenderRegistrationModel *)model;

- (void)authorizationFacadeDidFinishedAuthorization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;
- (void)authorizationFacadeDidFailedAuthorizationWithModel:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;

- (void)authorizationFacadeDidFinishedDeauthorization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;
- (void)      authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
didFailedDeauthorizationWithError:(NSError *)error;

- (void)authorizationFacadeWillStartSynchronization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;
- (void)authorizationFacadeDidFinishSynchronization:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;
- (void)      authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade
didFailedSynchronizationWithError:(NSError *)error;

- (SenderAuthBitcoinPasswordAction)passwordActionForMnemonic:(NSString *)mnemonic
                                         authorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;
- (NSString *)defaultWalletPasswordForAuthorizationFacade:(MWSenderAuthorizationFacade *)senderAuthorizationFacade;

@end

@interface MWSenderAuthorizationFacade : NSObject

@property (nonatomic, weak) id<MWSenderAuthorizationFacadeDelegate> delegate;

- (void)startFullAuthorization;
- (void)startSSOAuthorizationWith:(NSString *)authToken;
- (void)deauthorize;

- (void)synchronize:(NSError **)error isBitcoinEnabled:(BOOL)isBitcoinEnabled;

- (BOOL)isSynchronizationInProgress;

@property (nonatomic, weak) UINavigationController * navigationController;

@end
