//
//  SenderJsonConvertrer.m
//  Privat24
//
//  Created by Eugene Gilko on 12/12/13.
//  Copyright (c) 2013 Middleware Inc. All rights reserved.
//

#import "SenderJsonConvertrer.h"

@implementation SenderJsonConvertrer

+ (NSString *)makeJsonFromArray:(NSArray *)data
{
    NSError* error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
