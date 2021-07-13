//
//  Message.m
//  SENDER
//
//  Created by Eugene on 4/8/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "Message.h"
#import "Dialog.h"
#import "CoreDataFacade.h"
#import "ParamsFacade.h"
#import "ECCWorker.h"
#import "SecGenerator.h"
#import "NSString+WebService.h"
#import "MWMessagesCryptography.h"
#import "Contact.h"

@implementation Message
{
    NSNumber * _isDeleted;
}

@dynamic chat;
@dynamic classRef;
@dynamic companyId;
@dynamic created;
@dynamic data;
@dynamic deliver;
@dynamic formId;
@dynamic fromId;
@dynamic fromname;
@dynamic title;
@dynamic linkID;
@dynamic modelData;
@dynamic moId;
@dynamic robotId;
@dynamic type;
@dynamic dialog;
@dynamic file;
@dynamic encrypted;
@dynamic procId;
@dynamic packetID;
@dynamic editID;
@dynamic operatorName;
@dynamic operatorImageURL;

@synthesize indexPath;
@synthesize owner;
@synthesize viewForCell;
@synthesize isLoadingFile;

@synthesize previewText = _previewText;
@synthesize textMessage = _textMessage;
@synthesize authorImageURL = _authorImageURL;
@synthesize authorName = _authorName;
@synthesize authorContact = _authorContact;

- (NSString *)packetID
{
    [self willAccessValueForKey:@"packetID"];
    NSString * packetID = [self primitiveValueForKey:@"packetID"];
    [self didAccessValueForKey:@"packetID"];
    if (!packetID)
    {
        [self setPrimitiveValue:@"-1" forKey:@"packetID"];
        packetID = @"-1";
    }
    return packetID;
}

- (void)setPacketID:(NSString *)packetID
{
    [self willChangeValueForKey:@"packetID"];
    [self setPrimitiveValue:packetID forKey:@"packetID"];
    if (self.dialog)
        [self.dialog fixPositionOfMessage:self];
    [self didChangeValueForKey:@"packetID"];
}

- (void)setCreated:(NSDate *)created
{
    [self willChangeValueForKey:@"created"];
    [self setPrimitiveValue:created forKey:@"created"];
    if (self.dialog)
        [self.dialog updateLastMessage];
    [self didChangeValueForKey:@"created"];
}

- (void)setFromId:(NSString *)fromId
{
    [self willChangeValueForKey:@"fromId"];
    [self setPrimitiveValue:fromId forKey:@"fromId"];
    [self didChangeValueForKey:@"fromId"];
    _authorImageURL = nil;
    _authorContact = nil;
    _authorImageURL = nil;
}

- (void)setData:(NSData *)data
{
    [self willChangeValueForKey:@"data"];
    [self setPrimitiveValue:data forKey:@"data"];
    _textMessage = nil;
    _previewText = nil;
    _isDeleted = nil;
    if (self.moId && [self.dialog.lastMessage.moId isEqualToString:self.moId])
        [self.dialog updateLastMessage];
    [self didChangeValueForKey:@"data"];
}

- (void)setEncrypted:(NSNumber *)encrypted
{
    [self willChangeValueForKey:@"encrypted"];
    [self setPrimitiveValue:encrypted forKey:@"encrypted"];
    _textMessage = nil;
    _previewText = nil;
    if (self.moId && [self.dialog.lastMessage.moId isEqualToString:self.moId])
        [self.dialog updateLastMessage];
    [self didChangeValueForKey:@"encrypted"];
}

- (CGFloat)heightConsoleForm
{
    return self.viewForCell.frame.size.height;
}

- (BOOL)owner
{
    return [self.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID];
}

- (NSDate *)editLimit
{
    return [self.created dateByAddingTimeInterval:30 * 60];
}

- (void)updateWithText:(NSString *)text encryptionEnabled:(BOOL)encryptionEnabled
{
    self.encrypted = @(encryptionEnabled);
    if (!encryptionEnabled)
        self.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"text":text,@"pkey":@""}];
}

- (Dialog *)fmlDialog
{
    return self.dialog;
}

- (NSString *)textMessage
{
    if (!_textMessage)
    {
        if (![self.encrypted boolValue])
        {
            NSDictionary * data = [[ParamsFacade sharedInstance] dictionaryFromNSData:self.data];
            _textMessage = data[@"text"];
        }
        else
        {
            _textMessage = [MWMessagesCryptography decryptedMessageTextOfMessage:self inChat:self.dialog];
            if ([_textMessage length] == 0) _textMessage = nil;
        }
    }
    return _textMessage;
}

- (BOOL)isDeletedMessage
{
    if (!_isDeleted)
    {
        NSDictionary * data = [[ParamsFacade sharedInstance] dictionaryFromNSData:self.data];
        _isDeleted = @([self.type isEqualToString:@"TEXT"] && [data[@"text"] length] == 0);
    }
    return _isDeleted.boolValue;
}

- (BOOL)isEditedMessage
{
    return [self.linkID length] && [self.packetID length] && ![self.linkID isEqualToString:self.packetID];
}

- (NSString *)previewText
{
    if (!_previewText)
    {
        if (self.isDeletedMessage)
        {
            _previewText = @"lst_msg_text_for_lc_deleted_ios";
        }
        else
        {
            NSString * messageType = self.type;
            if ([messageType isEqualToString:@"TEXT"])
            {
                _previewText = self.textMessage;
                if ([self.encrypted boolValue] && ![_previewText length])
                    _previewText = @"lst_msg_text_for_lc_encrypted_text_ios";
            }
            else if ([messageType isEqualToString:@"IMAGE"])
                _previewText = @"lst_msg_text_for_lc_image_msg_ph_ios";
            else if ([messageType isEqualToString:@"VIDEO"])
                _previewText = @"lst_msg_text_for_lc_video_ios";
            else if ([messageType isEqualToString:@"SELFLOCATION"])
                _previewText = @"lst_msg_text_for_lc_location_ios";
            else if ([messageType isEqualToString:@"AUDIO"])
                _previewText = @"lst_msg_text_for_lc_voice_message_ios";
            else if ([messageType isEqualToString:@"FILE"])
                _previewText = @"lst_msg_text_for_lc_file_ios";
            else if ([messageType isEqualToString:@"VIBRO"])
                _previewText = @"lst_msg_text_for_lc_vibro_msg_ph_ios";
            else if ([messageType isEqualToString:@"STICKER"])
                _previewText = @"lst_msg_text_for_lc_sticker_msg_ph_ios";
            else if ([messageType isEqualToString:@"NOTIFICATION"])
                _previewText = self.textMessage;
            else if ([messageType isEqualToString:@"KEYCHAT"])
                _previewText = self.textMessage;
            else if ([messageType isEqualToString:@"FORM"])
                _previewText = self.title ?: @"lst_msg_text_for_lc_form_msg_ph_ios";
        }
    }
    return _previewText;
}

- (Contact *)authorContact
{
    if (!_authorContact)
    {
        if (self.dialog && self.dialog.isP2P)
            _authorContact = self.dialog.p2pContact;
        if (!_authorContact)
            _authorContact = [[CoreDataFacade sharedInstance] selectContactById:self.fromId];

    }
    return _authorContact;
}


- (NSURL *)authorImageURL
{
    if (!_authorImageURL)
    {
        if ([self.authorContact imageURL])
            _authorImageURL = [[NSURL alloc] initWithString:[self.authorContact imageURL]];
    }
    return _authorImageURL;
}

- (NSString *)authorName
{
    if (!_authorName)
        _authorName = self.authorContact.name;
    return _authorName;
}

@end
