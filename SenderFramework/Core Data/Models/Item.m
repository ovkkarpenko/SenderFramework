//
//  Item.m
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "Item.h"


@implementation Item

@dynamic type;
@dynamic value;

- (void)setDataFromDictionary:(NSDictionary *)data
{
    if (data[@"value"])
        self.value = data[@"value"];
    else if (data[@"valueRaw"])
        self.value = data[@"valueRaw"];
    self.type = data[@"type"];
}

@end
