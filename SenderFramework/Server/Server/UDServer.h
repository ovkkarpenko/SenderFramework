//
//  UDServer.h
//  SENDER
//
//  Created by Eugene on 3/4/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWReachability.h"
#import "RequestHolder.h"

@interface UDServer : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)uploadFileWithParams:(NSDictionary *)params
                    postData:(id)postData
           completionHandler:(SenderRequestCompletionHandler)completionHandler;

- (void)downloadFileWithUrl:(NSString *)urlString
          completionHandler:(SenderRequestCompletionHandler)completionHandler;

@end
