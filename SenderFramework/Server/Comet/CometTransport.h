//
//  CometTransport.h
//  SENDER
//
//  Created by Eugene Gilko on 12/15/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CometTransport : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (void)runForegroundComet;
- (void)runBackgroundComet:(NSDictionary *)userInfo
        withRequestHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (BOOL)stopComet;

- (void)setCometBlocked:(BOOL)cometBlocked;

@end