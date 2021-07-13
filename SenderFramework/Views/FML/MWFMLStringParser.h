//
// Created by Roman Serga on 9/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Dialog;

@interface MWFMLStringParser : NSObject

+ (void)parseFMLString:(NSString * _Nonnull)originalString
               forChat:(Dialog *)chat
     completionHandler:(void(^)(NSString * _Nullable parsedString))completionHandler;

@end