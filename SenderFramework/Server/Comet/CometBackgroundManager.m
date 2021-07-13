//
//  CometBackgroundManager.m
//  SENDER
//
//  Created by Eugene Gilko on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "CometBackgroundManager.h"
#import "NSString+WebService.h"
#import "SenderRequestBuilder.h"
#import "CometController.h"

static CometBackgroundManager * controller;

@implementation CometBackgroundManager
{
    NSURLSession * mainDataSession;
    NSNumber * msgCount;
    NSString * lastReceivedBatchID;
    NSURLSessionTask * cometDataTask;
    BOOL cometRun;

}

+ (CometBackgroundManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        controller = [[CometBackgroundManager alloc] init];
    });
    
    return controller;
}

- (id)init
{
    self = [super init];
    
    if(self) {
        cometRun = NO;
        lastReceivedBatchID = @"";
    }
    
    return self;
}

- (NSURLSession *)mainSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setAllowsCellularAccess:YES];
        [config setHTTPAdditionalHeaders:@{@"Content-Encoding":@"gzip"}];
        [config setHTTPAdditionalHeaders:@{@"Accept":@"application/json"}];
        [config setHTTPAdditionalHeaders:@{@"Content-Type":@"application/json"}];
        [config setTimeoutIntervalForRequest:60];
        [config setTimeoutIntervalForResource:0];
        [config setHTTPMaximumConnectionsPerHost:1];
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    
    return session;
}
//
//- (NSURLSession *)mainSession
//{
//    static NSURLSession * session = nil;
//    static dispatch_once_t onceToken;
//    
//    dispatch_once(&onceToken, ^{
//        
//        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.Sender.BackgroundSession"];
//        [config setAllowsCellularAccess:YES];
//        [config setTimeoutIntervalForResource:0];
//        [config setHTTPMaximumConnectionsPerHost:1];
//        [config setHTTPAdditionalHeaders:@{@"Content-Encoding":@"gzip"}];
//        [config setHTTPAdditionalHeaders:@{@"Accept":@"application/json"}];
//        [config setHTTPAdditionalHeaders:@{@"Content-Type":@"application/json"}];
//        [config setTimeoutIntervalForRequest:60];
//        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
//    });
//    
//    return session;
//}
//
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)runComet
{

    [[self mainSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        NSUInteger count = [dataTasks count] + [uploadTasks count] + [downloadTasks count];
        if (count > 0) {
            return;
        }
        
    }];
    
    if (cometRun) {
        
        // NSLog(@"COMET Blocked ============= \n");
        return;
    }
    
    cometRun = YES;
    
    NSDictionary * meta = @{@"net":@"wifi"};
    
    msgCount = [CometController sharedInstance].isWWAN ? @7:@15;
    
    NSDictionary * postData = @{@"meta":meta,@"lbi":lastReceivedBatchID,@"size":msgCount};
    
    NSURLRequest * theRequest = [[SenderRequestBuilder sharedInstance] requestWithPath:@"comet" urlParams:[[SenderRequestBuilder sharedInstance] urlStringParams] postData:postData timeOutInterval:60];
    
    // NSLog(@"START COMET");
    [self createConnectionWithRequest:theRequest andRequestHolder:nil];
    cometDataTask = [[self mainSession] dataTaskWithRequest:theRequest];
    [cometDataTask resume];
}

- (void)createConnectionWithRequest:(NSURLRequest *)request
                   andRequestHolder:(RequestHolder *)requestHolder
{
    // NSLog(@"\n  =========== REQUEST TO SERVER ===========\n %@", request);
   dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    
    NSURLSessionTask * postDataTask = [[self mainSession] dataTaskWithRequest:request];
    
//    NSString * indificator = [NSString stringWithFormat:@"%lu",(unsigned long)postDataTask.taskIdentifier];
    
    [postDataTask resume];
   });
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionTask *)dataTask didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionTask *)dataTask didReceiveData:(NSData *)data {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        // NSLog(@"\n ============== FROM COMET SERVER STRING  ============== \n %@", result);
        NSDictionary * resultDictionary = [result JSON];
    //    NSString * tastIndificator = [NSString stringWithFormat:@"%lu",(unsigned long)dataTask.taskIdentifier];
    //    
        // NSLog(@"\n ==============  RETURNED COMET RESULT FOR TASK #%lu ============== \n %@",(unsigned long)dataTask.taskIdentifier, resultDictionary);
        
        if(data) {
            
            NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSDictionary * response = [result JSON];
            
            if (resultDictionary) {
                
                if (response[@"bi"])
                    lastReceivedBatchID = response[@"bi"];
                
                if (response[@"fs"] && ((NSArray *)response[@"fs"]).count) {
                    
//                    if ([[CometController sharedInstance] sendToParse:response[@"fs"]]) {
//                        
//                    }
                }
                
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            cometRun = NO;
            [self runComet];
        });
    });
}

//
//    if (sessionTasks[tastIndificator]) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            RequestHolder * requestHolder = sessionTasks[tastIndificator];
//
//            if (requestHolder.completionHandler) {
//
//                requestHolder.completionHandler(resultDictionary, nil);
//                [sessionTasks removeObjectForKey:tastIndificator];
//            }
//        });
//    }


#pragma mark NSSession delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // NSLog(@"\n === \n FINISH \n ==== \n %@", task);
    
    if (!error) {
        
    }
    
    [self callCompletionHandlerIfFinished];
}

- (void)callCompletionHandlerIfFinished
{
    [[self mainSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSUInteger count = [dataTasks count] + [uploadTasks count] + [downloadTasks count];
        if (count == 0) {
        
            if ([CometController sharedInstance].backgroundTransferCompletionHandler == nil) return;
            void (^completionHandler)() = [CometController sharedInstance].backgroundTransferCompletionHandler;
            [CometController sharedInstance].backgroundTransferCompletionHandler = nil;
            LLog(@"\n === \n FINISH ALL TASK IN BACK SESSION \n ==== \n==== \n==== \n==== \n==== \n==== \n==== \n");
            completionHandler();
        }
    }];
}

@end
