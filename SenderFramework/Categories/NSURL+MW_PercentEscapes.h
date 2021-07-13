//
//  NSURL+PercentEscapes.h
//  SENDER
//
//  Created by Roman Serga on 01/6/16.
//  Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (MW_PercentEscapes)

+ (nullable instancetype)mw_URLByAddingPercentEscapesToString:(NSString * _Nonnull)URLString;

@end
