//
//  Message.h
//  Sender
//
//  Created by Eugene Gilko on 9/12/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Message.h"

@interface MessageEmpy : NSObject <MessageObject>

@property (nonatomic, strong) NSString * chat;
@property (nonatomic, strong) NSDate * created;
@property (nonatomic, strong) NSData * data;
@property (nonatomic, strong) NSString * deliver;
@property (nonatomic, strong) NSString * fromId;
@property (nonatomic, strong) NSString * fromname;
@property (nonatomic, strong) NSString * packetID;
@property (nonatomic, strong) NSString * linkID;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * moId;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, retain) Dialog *dialog;

@property (nonatomic, weak) NSIndexPath * indexPath;
@property (nonatomic) BOOL owner;
@property (nonatomic, strong) UIView * viewForCell;

- (CGFloat)heightConsoleForm;
- (BOOL)owner;

@end
