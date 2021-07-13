//
//  CometController.h
//  SENDER
//
//  Created by Eugene on 4/15/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "RequestHolder.h"

@interface CometController : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

+ (CometController *)sharedInstance;

- (void)cometRestart;
- (void)stopComet;

- (void)addMessageToQueue:(NSDictionary *)postData
              withUrlPath:(NSString *)path
     withCompletionHolder:(SenderRequestCompletionHandler)completionHolder;

- (void)addMessageToQueue:(NSDictionary *)postData
                getParams:(NSDictionary *)getParams
              withUrlPath:(NSString *)path
     withCompletionHolder:(SenderRequestCompletionHandler)completionHolder;

- (void)collectSendRequest:(NSDictionary *)postData
               withUrlPath:(NSString *)path
      withCompletionHolder:(SenderRequestCompletionHandler)completionHolder;

- (BOOL)setTokenWithChallenge:(NSString *)challenge;
- (void)startCometFromBackData:(NSDictionary *)userInfo
            withRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (BOOL)isWWAN;
- (void)setupReachability;
- (void)createDirectRequestWithPath:(NSString *)path
                           postData:(id)postData
               withCompletionHolder:(SenderRequestCompletionHandler)completionHolder;

- (void)createHTTPRequest:(NSString *)onlineKey
       withRequestHandler:(SenderRequestCompletionHandler)completionHolder;

- (void)createDirectRequest:(RequestHolder *)holder;
- (BOOL)checkForReachability;
- (NSDictionary *)createSimpleRequest:(NSDictionary *)postData
                          withUrlPath:(NSString *)path;

@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();
@property (nonatomic) BOOL isPaused;

- (void)systemReset;
- (BOOL)serverAvailable;
- (NSString *)lastBatchID;
- (void)trySendMessage;
- (void)resetAndRestart;
- (BOOL)checkResponse:(NSURLResponse *)response andError:(NSError *)error;

@end
