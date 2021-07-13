//
//  CometTransport.m
//  SENDER
//
//  Created by Eugene Gilko on 12/15/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "CometTransport.h"
#import "SenderRequestBuilder.h"
#import "SecGenerator.h"
#import "NSString+WebService.h"
#import "ServerFacade.h"
#import "SenderNotifications.h"
#import "ParamsFacade.h"
#import "CometController.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "LogerDBController.h"
#import "MW_PSPDFThreadSafeMutableDictionary.h"

@interface CometTransport()
{
    NSOperationQueue * cometQueue;
    MW_PSPDFThreadSafeMutableDictionary * taskArray;
    NSMutableData * tempData;
    BOOL cometBlocker;
    NSLock * sessionManagerLock;
    NSString * lastReceivedBatchID;
    NSTimer * cometTimer;
}

@end

@implementation CometTransport

- (id)init
{
    if (self = [super init])
    {
        sessionManagerLock = [[NSLock alloc] init];
        sessionManagerLock.name = @"SenderCometLock";
        cometQueue = [[NSOperationQueue alloc] init];
        [cometQueue setMaxConcurrentOperationCount:1];
        taskArray = [[MW_PSPDFThreadSafeMutableDictionary alloc] initWithCapacity:0];
        lastReceivedBatchID = @"";
        cometBlocker = NO;
    }
    
    return self;
}

- (void)lock
{
    [sessionManagerLock lock];
}

- (void)unlock
{
    [sessionManagerLock unlock];
}

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

- (NSURLSession *)mainSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration * config = [self getBasicConfig];
        [config setTimeoutIntervalForRequest:60];
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:cometQueue];
    });
    
    return session;
}

- (void)timerFired
{
    [self stopComet];
    [self runForegroundComet];
}

- (void)timerInvalidate
{
    @synchronized (self) {
        [cometTimer invalidate];
        cometTimer = nil;
    }
}

- (void)runTimer
{
    if (cometTimer) {
        [self timerInvalidate];
    }
    
    cometTimer = [NSTimer timerWithTimeInterval:61.0
                                        target:self
                                        selector:@selector(timerFired)
                                        userInfo:nil
                                         repeats:NO];
}

- (void)runForegroundComet
{
    if (taskArray.count) {
        return;
    }
    
    [self runTimer];

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [self createDataTasksWithSession:[self mainSession]
                              forRequest:[self getCometRequestForeGround]
                    withCompletionHolder:^(NSDictionary *resultDictionary, NSError *error) {
               
                if ([resultDictionary[@"code"] integerValue] == 0)
                {
    //                __block BOOL needReload = NO;
                    
                    dispatch_async(dispatch_get_main_queue(), ^() {
                                            
                        if (resultDictionary[@"fs"] && ((NSArray *)resultDictionary[@"fs"]).count) {
    //                        [self lock];
                            [[MWCometParser shared] parseCometResponseArray:resultDictionary[@"fs"]];
                            [[CoreDataFacade sharedInstance] saveContext];
    //                        [self unlock];
                        }
                    });
                }
                else {
                    
                    if ([resultDictionary[@"code"] integerValue] == 1) {
                        [self restartWithChallenge:resultDictionary];
                    }
                    else if ([resultDictionary[@"code"] integerValue] == 3) {
                        [[CometController sharedInstance] systemReset];
                    }
                    else if ([resultDictionary[@"code"] integerValue] == 5) {
            
                        if ([self stopComet]) {
                            [self runForegroundComet];
                        }
                    }
                    else {
                        
                        if ([self stopComet]) {
                            [self runForegroundComet];
                        }
                    }
                    
    //                [self unlock];
                }
        }];
    });
}

- (void)setCometBlocked:(BOOL)cometBlocked
{
    cometBlocker = cometBlocked;
}

- (BOOL)checkBackTaskState
{
    return taskArray.count == 0;
}

- (void)runBackgroundComet:(NSDictionary *)userInfo
        withRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (taskArray.count) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }

    if (![[CometController sharedInstance] serverAvailable]) {
        [[CometController sharedInstance] checkForReachability];
    }
    
    [self createDataTasksWithSession:[self mainSession]
                          forRequest:[self getCometRequestBackGround:userInfo]
                withCompletionHolder:^(NSDictionary *resultDictionary, NSError *error) {
                    
        if (resultDictionary) {
            
            if ([resultDictionary[@"code"] integerValue] == 0) {
                
                dispatch_async(dispatch_get_main_queue(), ^() {
                    
                    if (resultDictionary[@"fs"] && ((NSArray *)resultDictionary[@"fs"]).count) {
                        
                        if ([SENDER_SHARED_CORE.senderVersion integerValue] > 9) {
                            [[MWCometParser shared] parseCometResponseArray:resultDictionary[@"fs"]];
                        }
                    }

                    [self closeBackCometWithRequestHandler:completionHandler];
                });
            }
            else if ([resultDictionary[@"code"] integerValue] == 1) {
                
                [self restartWithChallengeFromBack:resultDictionary userInfo:userInfo withRequestHandler:completionHandler];
            }
            else if ([resultDictionary[@"code"] integerValue] == 3) {
                [[CometController sharedInstance] systemReset];
                completionHandler(UIBackgroundFetchResultNewData);
                return;
            }
            else if ([resultDictionary[@"code"] integerValue] == 5) {

                if ([self stopComet]) {
                    [self runBackgroundComet:userInfo withRequestHandler:completionHandler];
                }
            }
            else {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }
        else {
            completionHandler(UIBackgroundFetchResultNewData);
        }
    }];
}

- (void)closeBackCometWithRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSDictionary * meta = @{@"net":@"wifi",};
    NSDictionary * postWithDict = @{@"meta":meta,@"lbi":lastReceivedBatchID,@"connection":@"close",@"size":@5};
    NSMutableDictionary * urlP = [[[SenderRequestBuilder sharedInstance] urlStringParams] mutableCopy];
//    [urlP setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"rid"];
    
    NSURLRequest * request = [[SenderRequestBuilder sharedInstance] requestWithPath:@"comet" urlParams:urlP postData:postWithDict timeOutInterval:60];
    if ([self stopComet]) {
        [self createDataTasksWithSession:[self mainSession]
                              forRequest:request
                    withCompletionHolder:^(NSDictionary *resultDictionary, NSError *error) {
                        
//                        if (resultDictionary && !error) {
////                            lastReceivedBatchID = @"";
//                        }
                        
                        completionHandler(UIBackgroundFetchResultNewData);
                    }];
    }
}

- (BOOL)stopComet
{
    @synchronized (taskArray) {

        [self setCometBlocked:YES];
        
        if (taskArray.count) {
            
            NSDictionary * opDict = [taskArray copy];
            
            for (id key in opDict) {
                
                NSURLSessionTask * dTask = [opDict objectForKey:key][@"data"][@"task"];
                [dTask cancel];
            }
            
            [taskArray removeAllObjects];
        }
    }

    [self setCometBlocked:NO];
    
    return YES;
}

- (NSURLRequest *)getCometRequestForeGround
{
    NSString * netType = @"wifi";
    if ([[ServerFacade sharedInstance] isWwan]) {
        netType = @"wwan";
    }
    NSDictionary * meta = @{@"net":netType};
    NSDictionary * postWithDict = @{@"meta":meta,@"lbi":lastReceivedBatchID,@"size":@50};
    NSMutableDictionary * urlP = [[[SenderRequestBuilder sharedInstance] urlStringParams]mutableCopy];
//    [urlP setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"rid"];
    
    return  [[SenderRequestBuilder sharedInstance] requestWithPath:@"comet" urlParams:urlP postData:postWithDict timeOutInterval:60];
}

- (NSURLRequest *)getCometRequestBackGround:(NSDictionary *)userInfo
{
    NSString * netType = @"wifi";
    if ([[ServerFacade sharedInstance] isWwan]) {
        netType = @"wwan";
    }
    NSDictionary * meta = @{@"net":netType};
    NSString * ref = userInfo[@"ref"] ? userInfo[@"ref"]:@"";
    NSDictionary * postWithDict = @{@"meta":meta,@"lbi":lastReceivedBatchID,@"ref":ref,@"size":@50,@"connection":@"back"};
    
    NSMutableDictionary * urlP = [[[SenderRequestBuilder sharedInstance] urlStringParams] mutableCopy];
//    [urlP setObject:[NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] forKey:@"rid"];
    return [[SenderRequestBuilder sharedInstance] requestWithPath:@"comet" urlParams:urlP postData:postWithDict timeOutInterval:60];
}

- (void)createDataTasksWithSession:(NSURLSession *)session
                        forRequest:(NSURLRequest *)request_
              withCompletionHolder:(SenderRequestCompletionHandler)completionHolder
{
    if (taskArray.count || cometBlocker) {
        return;
    }

    NSURLSessionTask * dTask = [session dataTaskWithRequest:request_];
    NSDictionary * data = @{@"task":dTask, @"complition": [completionHolder copy]};
    taskArray[[self taskToIDString:dTask]] = @{@"data": data};

    LLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>> START COMET TASK ID = %@ LBA %@\n\n\n<<<<<<<<<<<<<<", [self taskToIDString:dTask], lastReceivedBatchID);
    
    [dTask resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        if (error.code == -1009)
        {
            [self stopComet];
            [[CometController sharedInstance] checkForReachability];
            [[LogerDBController sharedCore] addLogEvent:@{@"event": @"LOST CONNECTION", @"error": error.description}];
            return;
        }
        
        LLog(@"Task finished with error  %@",error);
        if (error.code == -999) {
            return;
        }
    }
    
    if ([taskArray objectForKey:[self taskToIDString:(NSURLSessionTask *)task]]) {

        if (task.state == NSURLSessionTaskStateCanceling || task.state == NSURLSessionTaskStateCompleted) {
            [taskArray removeAllObjects];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![SenderCore sharedCore].isInBackground) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    if ([self stopComet]) {
                        [self runForegroundComet];
                    }
                });
            }
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    if (downloadTask.response && ([downloadTask.response class] == [NSHTTPURLResponse class])) {
        
        NSError * error;
        NSData * data;
        
        if (location) {
            data = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&error];
        }
        
        if ([[CometController sharedInstance] checkResponse:downloadTask.response andError:downloadTask.error]) {
            
            if (downloadTask.state == NSURLSessionTaskStateRunning) {

                NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary * resultDictionary = [result JSON];
                
                if (resultDictionary) {
                    [self completeTask:downloadTask withData:resultDictionary];
                }
                else {
                    
                    LLog(@"TRY TO RESTORE DATA with Length %lu",(unsigned long)tempData.length);
                    @try {
                        if (!tempData) {
                            tempData = [[NSMutableData alloc] init];
                        }
                        
                        [tempData appendData:data];
                        
                        NSString * mergeResult = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
                        NSDictionary * resultDictionary = [mergeResult JSON];
                        
                        if (resultDictionary) {
                            tempData = nil;
                            [self completeTask:downloadTask withData:resultDictionary];
                        }
                    }
                    @catch (NSException *exception) {
                        
                    }
                    @finally {
                        
                    }
                }
            }
        }
        else {
            [self completeTask:downloadTask withData:nil];
        }
    }
    else  {
        
        [self completeTask:downloadTask withData:nil];
        [[LogerDBController sharedCore] addLogEvent:@{@"event":@"LOST CONNECTION"}];
        LLog(@"NO CONNECTION");
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionTask *)dataTask didReceiveData:(NSData *)data
{
    if (dataTask.response && ([dataTask.response class] == [NSHTTPURLResponse class]))
    {
        if ([[CometController sharedInstance] checkResponse:dataTask.response andError:dataTask.error]) {

            if (dataTask.state == NSURLSessionTaskStateRunning) {

                NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary * resultDictionary = [result JSON];
                
                if (resultDictionary) {
                    [self completeTask:dataTask withData:resultDictionary];
                }
                else {
                    
                    LLog(@"TRY TO RESTORE DATA with Length %lu",(unsigned long)tempData.length);
                    @try {
                        if (!tempData) {
                            tempData = [[NSMutableData alloc] init];
                        }
                        
                        [tempData appendData:data];
                        
                        NSString * mergeResult = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
                        NSDictionary * resultDictionary = [mergeResult JSON];
                        
                        if (resultDictionary) {
                            tempData = nil;
                            [self completeTask:dataTask withData:resultDictionary];
                        }
                    }
                    @catch (NSException *exception) {
                        
                    }
                    @finally {
                        
                    }
                }
            }
        }
        else {
            [self completeTask:dataTask withData:nil];
        }
    }
    else  {
        
        [self completeTask:dataTask withData:nil];
        
        [[LogerDBController sharedCore] addLogEvent:@{@"event":@"LOST CONNECTION"}];
        LLog(@"NO CONNECTION");
    }
}

- (void)completeTask:(NSURLSessionTask *)dataTask withData:(NSDictionary *)result
{
    LLog(@"\n >>>>>>>>>>>>>>>>>>>>>>>>>>>>> COMET TASK ID = %@ COMPLETE", [self taskToIDString:dataTask]);
    
    if ([taskArray objectForKey:[self taskToIDString:dataTask]]) {
        
        LLog(@"\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>> COMET TASK ID: %@ VALID LBA %@ NEW BI %@ \n >>>>>>>>>>>>>>>>>>>>>>>>>>>>> COMET DATA: \n %@ \n\n<<<<<<<<<<<<<<",[self taskToIDString:dataTask],lastReceivedBatchID, result[@"bi"],result);
    
        SenderRequestCompletionHandler completionHolder = [self completionHolderForTask:dataTask];
        
        if (result && result[@"bi"])
            lastReceivedBatchID = result[@"bi"];
        
        if (completionHolder)
            completionHolder(result, nil);
    }
}

- (NSString *)taskToIDString:(NSURLSessionTask *)task
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)task.taskIdentifier];
}

- (SenderRequestCompletionHandler)completionHolderForTask:(NSURLSessionTask *)dataTask
{
    if (!dataTask || ![self taskToIDString:dataTask]) return nil;
    return [taskArray objectForKey:[self taskToIDString:dataTask]][@"data"][@"complition"];
}
         
#pragma mark Token and Callange operations

- (void)restartWithChallengeFromBack:(NSDictionary *)result
                            userInfo:(NSDictionary *)userInfo
                  withRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([self setTokenWithChallenge:result[@"challenge"]]) {
        if ([self stopComet]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self runBackgroundComet:userInfo withRequestHandler:completionHandler];
            });
        }
    }
}

- (void)restartWithChallenge:(NSDictionary *)result
{
    if ([self setTokenWithChallenge:result[@"challenge"]]) {
        if ([self stopComet]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self runForegroundComet];
            });
        }
    }
}

- (BOOL)setTokenWithChallenge:(NSString *)challenge
{
    return [[SecGenerator sharedInstance] recalculateTokenWithChalenge:challenge];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

@end
