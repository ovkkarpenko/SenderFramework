//
//  ActionCellModel.m
//  SENDER
//
//  Created by Eugene Gilko on 11/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "ActionCellModel.h"

@implementation ActionCellModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        [self setActionModel:dictionary];
    }
    return self;
}

- (void)setActionModel:(NSDictionary *)action
{
    self.cellName = action[@"name"];
    self.cellImageURL = action[@"photo"];
    self.cellOper = action[@"oper"];
    self.cellUserID = action[@"userId"];
    self.cellActionData = action[@"data"];
    self.cellClass = action[@"class"];
}

@end