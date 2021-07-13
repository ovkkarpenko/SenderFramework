//
//  SenderRequestBuilder.h
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenderRequestBuilder : NSObject

+ (SenderRequestBuilder *)sharedInstance;

- (nonnull NSMutableURLRequest *)requestWithPath:(NSString *)path
                               urlParams:(NSDictionary *)params
                                postData:(id)data;

- (nonnull NSMutableURLRequest *)requestWithPath:(NSString *)path
                               urlParams:(NSDictionary *)params
                                postData:(id)data
                         timeOutInterval:(int)timeOutInterval;

- (NSDictionary *)urlStringParams;
- (NSString *)senderServerURL;
- (void)gotNewIP:(NSDictionary *)newIPs;
- (void)changeServerURL;
- (NSString *)httpServerUrl;
- (void)initServersUrls;

@end
