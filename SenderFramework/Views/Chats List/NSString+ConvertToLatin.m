//
// Created by Roman Serga on 31/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "NSString+ConvertToLatin.h"


@implementation NSString (ConvertToLatin)

- (NSString *)convertedToLatin
{
    NSMutableString * convertedString = [self mutableCopy];
    if (self)
    {
        CFMutableStringRef stringRef = (__bridge CFMutableStringRef)convertedString;
        CFStringTransform(stringRef, NULL, kCFStringTransformToLatin, false);
    }
    return [convertedString copy];
}

@end