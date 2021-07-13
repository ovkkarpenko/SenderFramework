//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatTableViewCell.h"

@interface ChatTableViewCell (SelectedAccessory)

- (void)showSelectedAccessory;
- (void)showDeselectedAccessory;

@end