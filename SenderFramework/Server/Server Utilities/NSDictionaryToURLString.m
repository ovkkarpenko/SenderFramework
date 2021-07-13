//
//  NSDictionaryToURLString.m
//  MoneySend
//
//  Created by Eugene Gilko on 3/31/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import "NSDictionaryToURLString.h"
#import "NSString+WebService.h"

@implementation NSDictionaryToURLString

+ (NSString *)convertToULRString:(NSDictionary *)source
{
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in source) {
        NSString * param = [[[source objectForKey:key] description] URLEncode];
        if (!param) {
            param = @"";
        }
        NSString *part = [NSString stringWithFormat: @"%@=%@", key,param];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

NSString * convertToStringURL (NSDictionary * source)
{
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in source) {
        NSString * param = [[source objectForKey:key] URLEncode];
        NSString *part = [NSString stringWithFormat: @"%@=%@", key,param];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

@end
