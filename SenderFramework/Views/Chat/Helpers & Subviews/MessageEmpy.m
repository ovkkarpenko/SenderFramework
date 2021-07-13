//
//  Message.m
//  Sender
//
//  Created by Eugene Gilko on 9/12/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MessageEmpy.h"

@implementation MessageEmpy

@synthesize indexPath,
            viewForCell;

- (NSString *)packetID
{
    return @"-2";
}

- (CGFloat)heightConsoleForm
{
    return self.viewForCell.frame.size.height;
}

@end
