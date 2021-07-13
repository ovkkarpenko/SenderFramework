//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "GapMessage.h"
#import "MessagesGap.h"

@implementation GapMessage

- (instancetype)initWithGap:(MessagesGap *)gap
{
    self = [super init];
    if (self)
    {
        self.dialog = gap.dialog;
        self.startPacketID = gap.startPacketID;
        self.endPacketID = gap.endPacketID;
        self.type = @"MESSAGES_GAP";
        self.isActive = YES;
        self.gap = gap;
        self.created = gap.created;
    }
    return self;
}

- (CGFloat)heightConsoleForm
{
    return self.viewForCell.frame.size.height;
}

@end