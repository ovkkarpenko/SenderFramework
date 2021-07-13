//
//  AddressBook.h
//  SENDER
//
//  Created by Nick Gromov on 10/3/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface AddressBook : NSObject
{
    NSMutableArray * contactList;
    NSString * regionCode;
    BOOL isNeedNormalize;
}

- (void)loadContactsNormalized:(BOOL)normalize;

- (BOOL)requestAddressBookAccess;

//You must load contacts using -loadContactsNormalized: before using -getContacts method
- (NSArray<NSDictionary *> *)getContacts;

@end