//
// Created by Roman Serga on 5/12/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@class Dialog;
@class MessagesGap;

@interface GapMessage : NSObject<MessageObject>

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

@property (nonatomic) BOOL isActive;

@property (nonatomic, retain) NSNumber * startPacketID;
@property (nonatomic, retain) NSNumber * endPacketID;
@property (nonatomic, strong) MessagesGap * gap;

- (BOOL)owner;
- (CGFloat)heightConsoleForm;
- (instancetype)initWithGap:(MessagesGap *)gap;

@end