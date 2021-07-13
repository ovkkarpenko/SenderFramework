//
//  UDServer.m
//  SENDER
//
//  Created by Eugene on 3/4/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "UDServer.h"
#import "ServerFacade.h"
#import "NSString+WebService.h"
#import "SenderRequestBuilder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FileOperator.h"
#import "CometController.h"

@implementation UDServer
{
    UIView * connectingView;
    BOOL isRechable;
    BOOL isWan;
    NSMutableArray * filesRequestsQueue;
    NSMutableArray * dataRequestsQueue;
    MWReachability * checkReachable;
}

- (id)init {
    
    if (self = [super init]) {
        
        filesRequestsQueue = [[NSMutableArray alloc] initWithCapacity:0];
        dataRequestsQueue = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (NSURLSession *)mainQueueSession
{
    static NSURLSession * session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setAllowsCellularAccess:YES];
        
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

- (void)restartRequests
{
    if (!isRechable)
        return;
     
    while (dataRequestsQueue.count) {
        RequestHolder * holder = dataRequestsQueue.firstObject;
        [dataRequestsQueue removeObject:holder];
        
        NSURLRequest * theRequest = [[SenderRequestBuilder sharedInstance] requestWithPath:holder.path urlParams:holder.urlParams postData:holder.postData];
        [self createConnectionWithRequest:theRequest andRequestHolder:holder];
    }
}

- (void)restartFileQueue
{
    if (filesRequestsQueue.count) {
        RequestHolder * holder = filesRequestsQueue.firstObject;
        [filesRequestsQueue removeObject:holder];
        if (holder.requestType == SFileType) {
            [self performDownloadingWithRequestHolder:holder];
        }
    }
}

#pragma mark Connection request

- (void)createConnectionWithRequest:(NSURLRequest *)request
                   andRequestHolder:(RequestHolder *)requestHolder
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        NSURLSessionDataTask * postDataTask = [[self mainQueueSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSDictionary * resultDictionary = nil;
            if(!error && data)
            {
                NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                resultDictionary = [result JSON];
                
                if ([resultDictionary[@"code"] integerValue] == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (requestHolder.completionHandler)
                            requestHolder.completionHandler(resultDictionary, nil);
                        [self restartRequests];
                    });
                }
                else if (resultDictionary[@"code"] == [NSNull null]) {
                    
                    [self addHolderToQueue:requestHolder];
                }
            }
            else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addHolderToQueue:requestHolder];
                });
            }
            
            [self restartRequests];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [postDataTask resume];
        });
    });
}

- (void)addHolderToQueue:(RequestHolder *)requestHolder
{
    if (requestHolder) {
        [dataRequestsQueue addObject:requestHolder];
    }

    [self restartRequests];
}

- (void)downloadFileWithUrl:(NSString *)urlString
          completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    RequestHolder * holder = [[RequestHolder alloc] initWithUrl:urlString completionHandler:completionHandler];
    
    [filesRequestsQueue addObject:holder];
    [self restartFileQueue];
}

- (void)performDownloadingWithRequestHolder:(RequestHolder *)requestHolder
{
    [[FileOperator sharedInstance] downloadFileWithCompletionHandler:requestHolder];
}

- (void)performUploadingWithRequestHolder:(RequestHolder *)requestHolder
{
    NSURLRequest * theRequest = [[SenderRequestBuilder sharedInstance] requestWithPath:requestHolder.path
                                                                             urlParams:requestHolder.urlParams
                                                                              postData:requestHolder.postData];
    [self createConnectionWithRequest:theRequest andRequestHolder:requestHolder];
}

- (void)uploadFileWithParams:(NSDictionary *)params
                    postData:(id)postData
           completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    NSMutableDictionary * postWithDict = [[NSMutableDictionary alloc] initWithDictionary:params];
    postWithDict[@"sid"] = [ServerFacade sharedInstance].sid ? [ServerFacade sharedInstance].sid:@"";
    RequestHolder * holder = [[RequestHolder alloc] initWithPath:@"upload"
                                                       urlParams:postWithDict
                                                        postData:postData
                                               completionHandler:completionHandler];
    holder.requestType = SFileUploadType;

    [self performUploadingWithRequestHolder:holder];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

@end
