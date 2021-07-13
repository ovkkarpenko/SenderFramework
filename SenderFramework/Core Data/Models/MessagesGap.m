//
//  MessagesGap.m
//  SENDER
//
//  Created by Roman Serga on 8/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "MessagesGap.h"

@implementation MessagesGap

- (BOOL)containsPacketID:(NSInteger)packetID
{
    return [self.startPacketID integerValue] >= packetID && [self.endPacketID integerValue] <= packetID;
}

- (BOOL)isIdenticalToGap:(MessagesGap *)gap
{
    if (gap == nil) return NO;
    return [self.startPacketID isEqual:gap.startPacketID] && [self.endPacketID isEqual:gap.endPacketID];
}

@end
