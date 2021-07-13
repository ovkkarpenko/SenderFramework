//
//  Message.h
//  SENDER
//
//  Created by Eugene on 4/8/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "File.h"

@class Dialog, File, Contact;

@protocol MessageObject <NSObject>

@required

@property (nonatomic, retain) NSString * chat;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * deliver;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromname;
@property (nonatomic, strong) NSString * packetID;
@property (nonatomic, retain) NSString * linkID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * moId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Dialog * dialog;
@property (nonatomic, weak) NSIndexPath * indexPath;
@property (nonatomic) BOOL owner;
@property (nonatomic, strong) UIView * viewForCell;
@property (nonatomic, retain) NSString * classRef;

- (CGFloat)heightConsoleForm;
- (BOOL)owner;

@end

@interface Message : NSManagedObject <MessageObject>

@property (nonatomic, retain) NSString * chat;
@property (nonatomic, retain) NSString * companyId;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * deliver;
@property (nonatomic, retain) NSString * formId;
@property (nonatomic, retain) NSString * fromId;
@property (nonatomic, retain) NSString * fromname DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * linkID;
@property (nonatomic, retain) NSData * modelData;
@property (nonatomic, retain) NSString * moId;
@property (nonatomic, retain) NSString * robotId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Dialog *dialog;
@property (nonatomic, retain) File *file;
@property (nonatomic, retain) NSNumber * encrypted;
@property (nonatomic, strong) NSString * procId;
@property (nonatomic, strong) NSString * packetID;
@property (nonatomic, strong) NSString * editID;
@property (nonatomic, strong) NSString * operatorName;
@property (nonatomic, strong) NSString * operatorImageURL;

//not in DB property

@property (nonatomic, weak) NSIndexPath * indexPath;
@property (nonatomic) BOOL owner;
@property (nonatomic, strong) UIView * viewForCell;
@property (nonatomic, readonly, strong) NSString * textMessage;
@property (nonatomic, readonly) BOOL isDeletedMessage;
@property (nonatomic, readonly) BOOL isEditedMessage;
@property (nonatomic, readonly) NSDate * editLimit;

@property (nonatomic) BOOL isLoadingFile;

@property (nonatomic, strong, readonly, nullable) Contact * authorContact;
@property (nonatomic, strong, readonly, nullable) NSURL * authorImageURL;
@property (nonatomic, strong, readonly, nullable) NSString * authorName;

@property (nonatomic, strong, readonly) NSString * previewText;

- (BOOL)owner;

- (void)updateWithText:(NSString *)text encryptionEnabled:(BOOL)encryptionEnabled;

- (CGFloat)heightConsoleForm;
- (Dialog *)fmlDialog;

@end
