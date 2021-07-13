//
//  Dialog+CoreDataProperties.m
//  SENDER
//
//  Created by Roman Serga on 7/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Dialog+CoreDataProperties.h"
#import "CompanyCard+CoreDataClass.h"
#import "ChatMember+CoreDataClass.h"
#import "Item.h"

@implementation Dialog (CoreDataProperties)

@dynamic companyID;
@dynamic chatDescription;
@dynamic encrypted;
@dynamic encryptionKey;
@dynamic imageURL;
@dynamic lastMessageTime;
@dynamic lastMessageText;
@dynamic lastMessageStatusRaw;
@dynamic chatID;
@dynamic name;
@dynamic needSync;
@dynamic p2p;
@dynamic type;
@dynamic unreadCount;
@dynamic chatSettings;
@dynamic members;
@dynamic messages;
@dynamic owner;
@dynamic gaps;
@dynamic localID;
@dynamic state;
@dynamic sendBar;
@dynamic operatorSendBar;
@dynamic p2pContact;
@dynamic companyCard;
@dynamic admins;
@dynamic oldGroupKeysData;
@dynamic items;

@end
