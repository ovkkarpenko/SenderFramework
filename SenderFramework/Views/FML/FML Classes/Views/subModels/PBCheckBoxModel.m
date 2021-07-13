//
//  PBCheckBoxModel.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBCheckBoxModel.h"

@implementation PBCheckBoxModel

- (id)initWithData:(NSDictionary *)data
{
    self.title = [data[@"t"] description];
    self.value = [data[@"v"] description];
    self.imgLinkl = data[@"img"];
    self.action = data[@"action"];
    self.actions = data[@"actions"];
    return self;
}

@end
