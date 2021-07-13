//
//  CometController.m
//  SENDER
//
//  Created by Eugene on 4/15/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "CometController.h"
#import "FileDownloadInfo.h"
#import "CoreDataFacade.h"
#import "SecGenerator.h"
#import "SenderRequestBuilder.h"
#import "NSString+WebService.h"
#import "ServerFacade.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "SenderNotifications.h"
#import "CometBackgroundManager.h"
#import "CometTransport.h"
#import "NSDictionaryToURLString.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "MWReachability.h"

static CometController * controller;

@interface CometController()
{
    NSURLSession * mainDataSession;
    NSMutableDictionary * mainDataQueue;
    NSMutableArray * requestQueue;
    NSMutableArray * collectedSendQueue;
    NSMutableArray * visPushId;
    NSString * lastReceivedBatchID;

    NSArray * dataForParse;
    
    BOOL cometRun;
    BOOL sendRun;
    BOOL dataRun;
   
    NSURLSessionDownloadTask * sendDataTask;
    NSURLSessionDownloadTask * dataTask;

    NSOperationQueue * cometQueue;
    NSOperationQueue * sendQueue;
    NSOperationQueue * dataQueue;
    
    BOOL isReachable;
    BOOL isWWAN;
    BOOL isLock;
    MWReachability * checkReachable;
    UIView * connectingView;
    NSNumber * msgCount;
    NSString * netType;
    int currentUnread;
    NSTimer * mainTimer;
    CometTransport * cometTransport;
//    MWSendController * sCD;
}

@property (nonatomic,strong) MWReachability * reachability;
@end

@implementation CometController

+ (CometController *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        controller = [[CometController alloc] init];
    });
    
    return controller;
}

- (id)init
{
    self = [super init];
    
    if(self) {
        
        [CometBackgroundManager sharedInstance];
        cometTransport = [[CometTransport alloc] init];
        mainDataQueue = [[NSMutableDictionary alloc] init];
        requestQueue = [[NSMutableArray alloc] init];
        collectedSendQueue = [[NSMutableArray alloc] init];
        visPushId = [[NSMutableArray alloc] init];
        sendQueue = [[NSOperationQueue alloc] init];
        [sendQueue setMaxConcurrentOperationCount:1];
        dataQueue = [[NSOperationQueue alloc] init];
//        sCD = [[MWSendController alloc] init];
        lastReceivedBatchID = @"";

        [self setupReachability];
        [self checkForReachability];
        cometRun = NO;
        sendRun = NO;
        dataRun = NO;
    }
    
    return self;
}

- (void)setIsPaused:(BOOL)isPaused
{
    _isPaused = isPaused;
    [self stopComet];
    if (!_isPaused)
        [self cometRestart];
}

#pragma mark Sessions

- (NSURLSessionConfiguration *)getBasicConfig
{
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setAllowsCellularAccess:YES];
    [config setHTTPAdditionalHeaders:@{@"Connection":@"Upgrade"}];
    [config setHTTPAdditionalHeaders:@{@"Content-Encoding":@"gzip"}];
    [config setHTTPAdditionalHeaders:@{@"Accept":@"application/json"}];
    [config setHTTPAdditionalHeaders:@{@"Content-Type":@"application/json"}];
    
    return config;
}

- (NSURLSession *)sendSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration * config = [self getBasicConfig];
        [config setTimeoutIntervalForRequest:15];
        [config setTimeoutIntervalForResource:0];
        [config setHTTPMaximumConnectionsPerHost:1];
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:sendQueue];
    });
    
    return session;
}

- (NSURLSession *)regularSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setAllowsCellularAccess:YES];

        [config setHTTPAdditionalHeaders:@{@"Content-Encoding":@"gzip"}];
        [config setHTTPAdditionalHeaders:@{@"Accept":@"application/json"}];
        [config setHTTPAdditionalHeaders:@{@"Content-Type":@"application/json"}];
        [config setTimeoutIntervalForRequest:30];
        [config setTimeoutIntervalForResource:0];
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:dataQueue];
    });
    
    return session;
}

- (NSURLSession *)longSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration * config = [self getBasicConfig];
        [config setTimeoutIntervalForRequest:120];
        [config setHTTPMaximumConnectionsPerHost:1];
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:dataQueue];
    });
    
    return session;
}

#pragma mark Reachability

- (void)setupReachability
{
    if (!checkReachable) {
        NSString * remoteHostName = @"senderapi.com";
        checkReachable = [MWReachability reachabilityWithHostName:remoteHostName];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkNetworkStatus:)
                                                     name:kMWReachabilityChangedNotification object:nil];
    }
    
    [checkReachable startNotifier];
}

- (BOOL)checkForReachability
{
    MWReachability * r = [MWReachability reachabilityWithHostName:@"senderapi.com"];
    MWNetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == MWNetworkStatusNotReachable) {
        cometRun = NO;
        return NO;
    }

    dispatch_async(dispatch_get_main_queue(), ^{ [self removeConnectingView]; });
    isReachable = YES;
    cometRun = NO;
    return YES;
}

- (BOOL)isWWAN
{
    return isWWAN;
}

- (BOOL)serverAvailable
{
    return isReachable;
}

- (void)checkNetworkStatus:(NSNotification *)notice
{
    MWNetworkStatus internetStatus = [checkReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case MWNetworkStatusNotReachable:
        {
            dispatch_async(dispatch_get_main_queue(), ^{ [self addConnectingViewToWindow:SENDER_SHARED_CORE.window]; });
            isReachable = NO;
            cometRun = NO;
            break;
        }
        case MWNetworkStatusReachableViaWiFi:
        {
            cometRun = NO;
            dispatch_async(dispatch_get_main_queue(), ^{ [self removeConnectingView]; });
            isReachable = YES;
            isWWAN = NO;
            [self resetAndRestart];
            break;
        }
        case MWNetworkStatusReachableViaWWAN:
        {
            cometRun = NO;
            dispatch_async(dispatch_get_main_queue(), ^{ [self removeConnectingView]; });
            isReachable = YES;
            isWWAN = YES;
            [self resetAndRestart];
            break;
        }
    }
}

//- (NSString *)getIPAddress {
//    NSString *address = @"error";
//    struct ifaddrs *interfaces = NULL;
//    struct ifaddrs *temp_addr = NULL;
//    int success = 0;
//    
//    success = getifaddrs(&interfaces);
//    if (success == 0) {
//        
//        temp_addr = interfaces;
//        while(temp_addr != NULL) {
//            if(temp_addr->ifa_addr->sa_family == AF_INET) {
//                
//                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
//                    
//                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
//                }
//            }
//            temp_addr = temp_addr->ifa_next;
//        }
//    }
//    
//    freeifaddrs(interfaces);
//    
//    return address;
//}

#pragma mark Connection View

- (void)addConnectingViewToWindow:(UIWindow *)window
{
    if (!connectingView)
    {
        CGFloat width = 200.0f;
        CGFloat height = 30.0f;
        connectingView = [[UIView alloc]initWithFrame:CGRectMake((window.frame.size.width - width) / 2, 25.0f, width, height)];
        connectingView.backgroundColor = [[SenderCore sharedCore].stylePalette.alertColor colorWithAlphaComponent:0.2f];
        connectingView.layer.cornerRadius = 10.0f;
        connectingView.userInteractionEnabled = NO;

        UILabel * connectingLabel = [[UILabel alloc]initWithFrame:CGRectMake(15.0f, 0.0f, 120.0f, height)];
        connectingLabel.userInteractionEnabled = NO;
        connectingLabel.textColor = [[SenderCore sharedCore].stylePalette.alertColor colorWithAlphaComponent:0.5f];
        connectingLabel.text = SenderFrameworkLocalizedString(@"connecting_ios", nil);
        
        UIActivityIndicatorView * spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(width - height - 20.0f, 0.0f, height, height)];
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinner.color = [[SenderCore sharedCore].stylePalette.alertColor colorWithAlphaComponent:0.5f];
        [spinner startAnimating];
        
        [connectingView addSubview:connectingLabel];
        [connectingLabel addSubview:spinner];
        
        [window addSubview: connectingView];
    }
}

- (void)removeConnectingView
{
    if (connectingView)
    {
        [self justRun];
        [connectingView removeFromSuperview];
        connectingView = nil;
    }
}

#pragma mark Token and Callange operations

- (BOOL)setTokenWithChallenge:(NSString *)challenge
{
    return [[SecGenerator sharedInstance] recalculateTokenWithChalenge:challenge];
}

- (NSURLRequest *)buildRequestWithFileInfo:(FileDownloadInfo *)fileInfo
{
    NSMutableDictionary * urlP = [[NSMutableDictionary alloc] initWithDictionary:[[SenderRequestBuilder sharedInstance] urlStringParams]];
    
    if (fileInfo.holder.urlParams) {
        [urlP addEntriesFromDictionary:fileInfo.holder.urlParams];
    }

    if (fileInfo.cidID) {
        urlP[@"rid"] = fileInfo.cidID;
    }
    else {
        urlP[@"rid"] = [NSString stringWithFormat:@"%.0f", ([[NSDate date] timeIntervalSince1970] * 10000000)];
    }
    
    return [[SenderRequestBuilder sharedInstance] requestWithPath:fileInfo.holder.path urlParams:urlP postData:fileInfo.holder.postData];
}

- (BOOL)checkVersionResponse:(NSDictionary *)result
{
    if ([result isKindOfClass:[NSNull class]]) {
        [self resetAndRestart];
        return NO;
    }
    
    switch ([result[@"code"] integerValue]) {
        case 0:
            return YES;
        case 1:
            [self restartWithChallenge:result];
            return NO;
        case 3:
            [self systemReset];
            return NO;
        default:
            [self resetAndRestart];
            return NO;
    }
}

- (void)totalStop
{
    sendRun = YES;
    dataRun = YES;
}

- (void)totalRun
{
    [mainDataQueue removeAllObjects];
    [requestQueue removeAllObjects];
    [self justRun];
    [cometTransport setCometBlocked:NO];
}

- (void)justRun
{
    sendRun = NO;
    dataRun = NO;
}

- (void)systemReset
{
    [self totalStop];
    if ([cometTransport stopComet]) {
        [cometTransport setCometBlocked:YES];
    }

    [self startRegistrationFromCode];
}

- (NSString *)lastBatchID
{
    return lastReceivedBatchID;
}

- (void)startRegistrationFromCode
{
    [self cleanRequestQueues];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[SenderCore sharedCore] isInBackground]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LEAVE_FOR_RESTART" object:nil];
            Owner * owner = [[CoreDataFacade sharedInstance] getOwner];
            if (owner.authorizationState != OwnerAuthorizationStateNotAuthorized)
                [[SenderCore sharedCore] reset];
        }
    });
}

- (void)cleanRequestQueues
{
    [mainDataQueue removeAllObjects];
    [requestQueue removeAllObjects];
}

- (void)restartWithChallenge:(NSDictionary *)result
{
    if (!isLock) {
        isLock = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self setTokenWithChallenge:result[@"challenge"]]) {
                [self resetAndRestart];
                isLock = NO;
            }
        });
    }
}

- (void)resetAndRestart
{
    if ([[CoreDataFacade sharedInstance] getOwner].aid) {
        [self justRun];
        if (![SenderCore sharedCore].isInBackground) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self runRequestQueue];
                [self queueCoordinator];
                if (!self.isPaused)
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [cometTransport runForegroundComet];
                    });
                }
            });
        }
    }
}

#pragma mark REQUESTS
//
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    if ([self shouldTrustProtectionSpace:challenge.protectionSpace]) {
//        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//    } else {
//        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
//    }
//}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
//    if ([self shouldTrustProtectionSpace:challenge.protectionSpace]) {
//        
//        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
//    } else {
//        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
//    }
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);//
}

- (BOOL)shouldTrustProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    SecTrustRef serverTrust = protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
    NSString *cerPath = [SENDER_FRAMEWORK_BUNDLE pathForResource:@"cert" ofType:@"der"];
    NSData *localCertData = [NSData dataWithContentsOfFile:cerPath];
    return ([remoteCertificateData isEqualToData:localCertData]);
}

- (BOOL)checkResponse:(NSURLResponse *)response andError:(NSError *)error
{
    //NLog(@"DATA FROM SERVER (%lu) %@\nRESPONSE CODE: %li", 1,@{}/*response*/, [(NSHTTPURLResponse *)response statusCode]);

    if (response && ([response class] == [NSHTTPURLResponse class])) {
        int httpStatusCode = (int)[(NSHTTPURLResponse *)response  statusCode];
        
        if (httpStatusCode == 200) {
            return YES;
        }
        else {
//            [[LogerDBController sharedCore] addLogEvent:@{@"event":@"Can`t resolve server",@"Server response:":[NSString stringWithFormat:@"%@",response]}];
//            
            [[SenderRequestBuilder sharedInstance] changeServerURL];
        }
    }
    else if (error && error.code == NSURLErrorNotConnectedToInternet) {
        
        LLog(@"NO CONNECTION");
    }

    return NO;
}

- (void)createRequest:(FileDownloadInfo *)fileInfo
{
    if (!isReachable) {
        [self checkForReachability];
        return;
    }
    
    if (!fileInfo.isDownloading)
        fileInfo.isDownloading = YES;
    
    NSURLSession * session = [self regularSession];
    
    if ([fileInfo.holder.path isEqualToString:@"sync_ct"] ||
        [fileInfo.holder.path isEqualToString:@"sync_dlg"] ||
        [fileInfo.holder.path isEqualToString:@"auth_phone"] ||
        [fileInfo.holder.path isEqualToString:@"selfinfo_set"] ||
        [fileInfo.holder.path isEqualToString:@"auth_otp"])
    {
        session = [self longSession];
    }
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {

        NSURLRequest * request = [self buildRequestWithFileInfo:fileInfo];
        dataTask = [[self sendSession] downloadTaskWithRequest:request
                                             completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData * data;
            
            if (location) {
                data = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&error];
            }

            dataRun = NO;
            [requestQueue removeObject:fileInfo];
            fileInfo.isDownloading = NO;
            
            LLog(@"\n==================== SIMPLE TASK ID = %@ STOP \n=========================================\n WITH RESP %@\n ============== \n WITH ERROR %@",fileInfo.cidID,response,error);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                  
                  if (![self checkResponse:response andError:error]) {
                      if (fileInfo.holder.completionHandler)
                          fileInfo.holder.completionHandler(nil, error);
                      [requestQueue addObject:fileInfo];
                      
                      [self runRequestQueue];
                      return;
                  }
                
                if(data)
                {
                    NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSDictionary * resultDictionary = [result JSON];

                    NLog(@"DATA FROM SERVER (%lu_%p) %@\nRESPONSE CODE: %li", request.hash, &request, result, [(NSHTTPURLResponse *)response statusCode]);
                    LLog(@"\n ============== SIMPLE TASK ID = %@ VALID \n  %@",fileInfo.cidID,resultDictionary);
                    
                    if (resultDictionary && [resultDictionary[@"code"] integerValue] == 0) {
                
                            if (fileInfo.holder.completionHandler) {
                                fileInfo.holder.completionHandler(resultDictionary, nil);
                            }
                            [self runRequestQueue];
                    }
                    else if (resultDictionary && ([resultDictionary[@"code"] integerValue] == 10 || [resultDictionary[@"code"] integerValue] == 9)) {
                        [requestQueue removeObject:fileInfo];
                        if (fileInfo.holder.completionHandler) {
                            fileInfo.holder.completionHandler(resultDictionary, nil);
                        }
                        [self runRequestQueue];
                    }
                    else if (!resultDictionary || resultDictionary[@"code"] == [NSNull null]) {
                       
                            [requestQueue addObject:fileInfo];
                            
                            [self runRequestQueue];
                    }
                    else if (resultDictionary && [resultDictionary[@"code"] integerValue] == 2) {
                         [requestQueue removeObject:fileInfo];
                            if (fileInfo.holder.completionHandler) {
                                fileInfo.holder.completionHandler(resultDictionary, nil);
                            }
                        [self runRequestQueue];

                    }
                    else if (![self checkVersionResponse:resultDictionary]) {
                        
                        if ([fileInfo.holder.path isEqualToString:kRegPath] ||
                            [fileInfo.holder.path isEqualToString:kAuthPhonePath] ||
                            [fileInfo.holder.path isEqualToString:@"sync_ct"] ||
                            [fileInfo.holder.path isEqualToString:@"sync_dlg"])
                        {
                            [self createRequest:fileInfo];
                            return;
                        }
                        
                        if ([resultDictionary[@"code"] integerValue] != 14 &&
                            [resultDictionary[@"code"] integerValue] != 10 &&
                            [resultDictionary[@"code"] integerValue] != 3) {
                            [requestQueue addObject:fileInfo];
                        }
                        
                        return;
                    }
                    else {
                        return;
                    }
                }
                else if (error.code == NSURLErrorCancelled) {
                    return;
                }
                else {
                    
                    if ([fileInfo.holder.path isEqualToString:@"reg_light"]) {
                        [requestQueue addObject:fileInfo];
                    }

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self runRequestQueue];
                    });
                }               
           });

        }];
        
        LLog(@"\n==================== SIMPLE TASK ID = %@ START", fileInfo.cidID);
        
        [dataTask resume];
    });
}

- (void)createSendRequest:(FileDownloadInfo *)fileInfo
{
    if (!isReachable) {
        [self checkForReachability];
        return;
    }
    
    if (!fileInfo.isDownloading) {
        fileInfo.isDownloading = YES;
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){

            sendDataTask = [[self sendSession] downloadTaskWithRequest:[self buildRequestWithFileInfo:fileInfo] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSData * data;
                
                if (location) {
                    data = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&error];
                }
                
                LLog(@"\n==================== SEND TASK ID = %@ STOP \т===================================================\n WITH RESP %@\n ============== \n WITH ERROR %@",fileInfo.cidID,response,error);
                
                 sendRun = NO;
                
                 fileInfo.isDownloading = NO;
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (![self checkResponse:response andError:error]) {
                         if (fileInfo.holder.completionHandler)
                             fileInfo.holder.completionHandler(nil, error);
                         sendRun = NO;
                         [self queueCoordinator];
                         return;
                     }
                    
                     if (data)
                     {
                         NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                         NSDictionary * resultDictionary = [result JSON];
                         
                         LLog(@"\n ============== SEND TASK ID = %@ VALID \n  %@",fileInfo.cidID,resultDictionary);
                         
                         if (resultDictionary && [resultDictionary[@"code"] integerValue] == 0) {
                             [mainDataQueue removeObjectForKey:fileInfo.cidID];
                             if (fileInfo.holder.completionHandler) {
                                 fileInfo.holder.completionHandler(resultDictionary, nil);
                             }
                             [self queueCoordinator];
                         }
                         else if (!resultDictionary || resultDictionary[@"code"] == [NSNull null]) {
                             
                             [mainDataQueue removeObjectForKey:fileInfo.cidID];
                             [mainDataQueue setObject:fileInfo forKey:fileInfo.cidID];
                             [self queueCoordinator];
                         }
                         else if (resultDictionary && [resultDictionary[@"code"] integerValue] == 10) {
                             [mainDataQueue removeObjectForKey:fileInfo.cidID];

                             if (fileInfo.holder.completionHandler) {
                                 fileInfo.holder.completionHandler(resultDictionary, nil);
                             }
                             [self queueCoordinator];
                         }
                         else { return; }
                     }
                     else if (error.code == NSURLErrorCancelled) {
                         sendRun = NO;
                         return;
                     }
                     else {
                         
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             sendRun = NO;
                             [self queueCoordinator];
                         });
                     }
                });
                 
             }];

            LLog(@"\n==================== SEND TASK ID = %@ START", fileInfo.cidID);
            
            [sendDataTask resume];
        });
    }
}

- (NSDictionary *)createSimpleRequest:(NSDictionary *)postData
                          withUrlPath:(NSString *)URL
{
    NSMutableDictionary * urlP = [[NSMutableDictionary alloc] initWithDictionary:[[SenderRequestBuilder sharedInstance] urlStringParams]];
    NSMutableURLRequest * request = [[SenderRequestBuilder sharedInstance] requestWithPath:URL urlParams:urlP postData:postData];
    NSError * error;
    NSError * requestError;
    NSURLResponse * urlResponse = nil;

    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    
    if (!data) {
        return nil;
    }

    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
}

- (void)cometRestart
{
    if (![SenderCore sharedCore].isInBackground)
    {
        [self runRequestQueue];
        [self queueCoordinator];
        if (!self.isPaused)
            [cometTransport runForegroundComet];
    }
}

- (void)stopComet
{
    [cometTransport stopComet];
    LLog(@"COMET STOPPED ============>>>>>>");
}

- (void)trySendMessage
{
    if (!isReachable) {
        [self checkForReachability];
    }
}

#pragma mark SEND Request Manager

- (void)queueCoordinator
{
    if (sendRun || [SecGenerator sharedInstance].tempTokken.length < 1) {
        return;
    }
    
    @synchronized(mainDataQueue) {
    
        if (mainDataQueue.count) {
        
            NSArray * arr =  [[mainDataQueue allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            FileDownloadInfo * fdi = mainDataQueue[[arr firstObject]];
            
            sendRun = YES;
            if (fdi.taskIdentifier == -1)
                [self createSendRequest:fdi];
        }
    }
}

- (void)runRequestQueue
{
    if (dataRun) {
        return;
    }
    
    if (collectedSendQueue.count && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            for (RequestHolder * hTemp in collectedSendQueue) {
                [self addMessageToQueue:(NSDictionary *) hTemp.postData getParams:nil withUrlPath:hTemp.path withCompletionHolder:hTemp.completionHandler];
            }
            
            [collectedSendQueue removeAllObjects];
            collectedSendQueue = [NSMutableArray new];
    }
    
    if (requestQueue.count) {
        
        FileDownloadInfo * fdi = [requestQueue firstObject];
        dataRun = YES;
        if (fdi.taskIdentifier == -1)
            [self createRequest:fdi];
    }
}

- (void)addMessageToQueue:(NSDictionary *)postData
                getParams:(NSDictionary *)getParams
              withUrlPath:(NSString *)path
     withCompletionHolder:(SenderRequestCompletionHandler)completionHolder
{
//    MWSessionWorker * sW = [[MWSessionWorker alloc] init];
//    [sW runTest];
//    return;
    
    if (path) {

        NSMutableDictionary * postWithDict = nil;

        if ([path isEqualToString:kSendPath]) {

            postWithDict =  [[NSMutableDictionary alloc] initWithDictionary:@{@"fs":@""}];

            if (postData) {

                NSMutableDictionary * postAddons =  [[NSMutableDictionary alloc] initWithDictionary:postData];
                [postAddons setObject:[NSString stringWithFormat:@"%.0f", ([[NSDate date] timeIntervalSince1970] * 10000000)] forKey:@"cid"];
                postWithDict[@"fs"] = @[postAddons];

                RequestHolder * holder = [[RequestHolder alloc] initWithPath:path
                                                                   urlParams:getParams
                                                                    postData:postWithDict
                                                           completionHandler:completionHolder];

                FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];
                fdi.cidID = postAddons[@"cid"];
                [mainDataQueue setObject:fdi forKey:fdi.cidID];
                [self queueCoordinator];

                return;
            }
            else {
                return;
            }
        }
        else {

            if (postData) {
                postWithDict = [[NSMutableDictionary alloc] initWithDictionary:postData];
            }

            RequestHolder * holder = [[RequestHolder alloc] initWithPath:path
                                                               urlParams:getParams
                                                                postData:postWithDict
                                                       completionHandler:completionHolder];

            FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];

            if ([path isEqualToString:kRegPath] || [path isEqualToString:kSyncContactsPath] || [path isEqualToString:kSyncDialogsPath]) {
                isReachable = YES;
                [self createRequest:fdi];
            }
            else {

                if ([path isEqualToString:kRegLightPath]) {
                    isReachable = YES;
                }

                [requestQueue addObject:fdi];

                [self runRequestQueue];
            }

            return;
        }
    }
    else {

        NSMutableDictionary * postWithDict =  [[NSMutableDictionary alloc] initWithDictionary:@{@"fs":@""}];

        if (postData) {

            if ([postData[@"formId"] isEqualToString:@"text"] ||
                [postData[@"formId"] isEqualToString:@"image"] ||
                [postData[@"formId"] isEqualToString:@"file"] ||
                [postData[@"formId"] isEqualToString:@"audio"] ||
                [postData[@"robotId"] isEqualToString:@"sticker"] ||
                [postData[@"robotId"] isEqualToString:@"shareMyLocation"] ||
                [postData[@"robotId"] isEqualToString:@"vibro"] ||
                [postData[@"formId"] isEqualToString:@"kickass"])
            {
                NSMutableDictionary * postAddons =  [[NSMutableDictionary alloc] initWithDictionary:postData];

                [postAddons setObject:[NSString stringWithFormat:@"%.0f", ([[NSDate date] timeIntervalSince1970] * 10000000)] forKey:@"cid"];
                postWithDict[@"fs"] = @[postAddons];

                NSString * urlPath = kSendPath;

                RequestHolder * holder = [[RequestHolder alloc] initWithPath:kSendPath
                                                                   urlParams:getParams
                                                                    postData:postWithDict
                                                           completionHandler:completionHolder];
                FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];
                fdi.cidID = postAddons[@"cid"];
                [mainDataQueue setObject:fdi forKey:fdi.cidID];
                [self queueCoordinator];
            }
            else
            {
                NSMutableDictionary * postAddons =  [[NSMutableDictionary alloc] initWithDictionary:postData];
                [postAddons setObject:@"" forKey:@"cid"];
                postWithDict[@"fs"] = @[postAddons];
                RequestHolder * holder = [[RequestHolder alloc] initWithPath:kSendPath
                                                                   urlParams:getParams
                                                                    postData:postWithDict
                                                           completionHandler:completionHolder];

                FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];
                [requestQueue addObject:fdi];

                [self runRequestQueue];

                return;
            }
        }
    }
}

- (void)collectSendRequest:(NSDictionary *)postData
               withUrlPath:(NSString *)path
      withCompletionHolder:(SenderRequestCompletionHandler)completionHolder
{
    RequestHolder * backHolder = [[RequestHolder alloc] initWithPath:path
                                                       urlParams:nil
                                                        postData:postData
                                               completionHandler:completionHolder];
    
    [collectedSendQueue addObject:backHolder];
}

- (void)addMessageToQueue:(NSDictionary *)postData
              withUrlPath:(NSString *)path
     withCompletionHolder:(SenderRequestCompletionHandler)completionHolder
{
//    [sCD addQueueRequest:path postData:postData completionHolder:completionHolder];
    [self addMessageToQueue:postData getParams:nil withUrlPath:path withCompletionHolder:completionHolder];
}

- (void)startCometFromBackData:(NSDictionary *)userInfo
            withRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [cometTransport runBackgroundComet:userInfo withRequestHandler:completionHandler];
}

- (void)createDirectRequestWithPath:(NSString *)path postData:(id)postData withCompletionHolder:(SenderRequestCompletionHandler)completionHolder
{
    RequestHolder * holder = [[RequestHolder alloc] initWithPath:path urlParams:nil postData:postData completionHandler:completionHolder];
    [self createDirectRequest:holder];
}

- (void)createDirectRequest:(RequestHolder *)holder
{
    FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];

    dataRun = YES;
    if (fdi.taskIdentifier == -1)
        [self createRequest:fdi];
}

- (void)createHTTPRequest:(NSString *)onlineKey withRequestHandler:(SenderRequestCompletionHandler)completionHolder
{
    NSString * urlAsString  = [[SenderRequestBuilder sharedInstance] httpServerUrl];
    urlAsString = [urlAsString stringByAppendingString:@"?"];
    NSString * addString = [NSDictionaryToURLString convertToULRString:@{@"userId":[[CoreDataFacade sharedInstance] ownerUDID],@"online_key=":onlineKey}];
    urlAsString = [urlAsString stringByAppendingString:addString];
    NSURL * url = [[NSURL alloc] initWithString:urlAsString];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    
    NSURLSessionTask * httpTask = [[self regularSession] dataTaskWithRequest:request
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                             if (error) {
                                                 LLog(@"ERROR online key");
                                             }
         if (completionHolder) {
             if (!error) {
                 
                 NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 NSDictionary * resultDictionary = [result JSON];
                 
                 completionHolder(resultDictionary,nil);
             }
             else {
                 completionHolder(nil,nil);
             }
        }
     }];
    [httpTask resume];
}

//- (void)addQueue {
//dispatch_queue_t backgroundQueue() {
//    static dispatch_once_t queueCreationGuard;
//    static dispatch_queue_t queue;
//    dispatch_once(&queueCreationGuard, ^{
//        queue = dispatch_queue_create("com.sender.backgroundQueue", 0);
//    });
//    return queue;
//}
//}

@end
