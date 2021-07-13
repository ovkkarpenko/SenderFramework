//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "NSArray+EqualContents.h"

@implementation NSArray (EqualContents)

- (BOOL)isContentEqualToArray:(NSArray *)array
{
    if (!array || [self count] != [array count]) {
        return NO;
    }

    for (NSUInteger idx = 0; idx < [array count]; idx++) {
        if (![self[idx] isEqual:array[idx]]) {
            return NO;
        }
    }

    return YES;
}

@end