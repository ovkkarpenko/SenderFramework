//
//  CheckAddressBookChanges.m
//  SENDER
//
//  Created by Eugene on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "CheckAddressBookChanges.h"
#import "ServerFacade.h"
#import "CoreDataFacade.h"
#import "AddressBook.h"
#import "ParamsFacade.h"
#import "Owner.h"

@implementation CheckAddressBookChanges

- (id)init
{
    ABAddressBookRef book = ABAddressBookCreate();
    ABAddressBookRegisterExternalChangeCallback(book, addressBookChanged, (__bridge void *)(self));
    return self;
}

- (void)checkLocalContactArchive
{
//    if (![CoreDataFacade sharedInstance].getOwner.localContacts) {
    
        NSArray * locCont = [self convertContactsToHash:[self getCurrentContactArchive]];
        [CoreDataFacade sharedInstance].getOwner.localContacts = [[ParamsFacade sharedInstance] nSdateFromArray:locCont];
//    }
}

- (NSArray *)getCurrentContactArchive
{
    AddressBook * addressBook = [[AddressBook alloc] init];
    [addressBook loadContactsNormalized:YES];
    return addressBook.getContacts.count ? addressBook.getContacts:@[];
}

- (NSArray *)convertContactsToHash:(NSArray *)sourse
{
    NSMutableArray * resArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary * cont in sourse) {
        
        [resArray addObject:[NSNumber numberWithInteger:[self toHash:cont]]];
    }
    
    return (NSArray *)resArray;
}

+ (void)reBuildSenderContactList
{
    return;

    if (![CoreDataFacade sharedInstance].getOwner.localContacts) {
        return;
    }
    
    NSMutableArray * preparedData = [[NSMutableArray alloc] initWithCapacity:0];
    
    CheckAddressBookChanges * newWorker = [[CheckAddressBookChanges alloc] init];
    NSArray * newContArray = [newWorker getCurrentContactArchive];
    
    NSArray * storedAB = [[ParamsFacade sharedInstance] arrayFromNSData:[CoreDataFacade sharedInstance].getOwner.localContacts];
    
    for (NSDictionary * cCont in newContArray) {
        
        NSNumber * checkHash = [NSNumber numberWithInteger:[newWorker toHash:cCont]];
        
        if (![storedAB containsObject:checkHash]) {
            [preparedData addObject:cCont];
        }
    }
    
    if (preparedData.count) {
        
        for (NSDictionary * contactInfo in preparedData) {
            if (contactInfo[@"contactItemList"] && contactInfo[@"contactItemList"][0]) {
                if (contactInfo[@"contactItemList"][0][@"valueRaw"]) {
                    NSDictionary * resultFromServer = [[ServerFacade sharedInstance] getContactInfoByPhone:contactInfo[@"contactItemList"][0][@"valueRaw"]];
                    
                    /*
                     {
                     "code":"<code>"
                     "cts": [{
                     "userId": "<userId>",
                     "name": "<name>",
                     "photo": "<photo>",
                     "isCompany": "<isCompany>",
                     "isOwn": "<isOwn>"
                     }]
                     }
                     */
                }
            }
        }
        
        
    // DO SOMETHING !!!!
    }
}

void addressBookChanged(ABAddressBookRef notifyAddressBook,
                        CFDictionaryRef dictionary,
                        void *context)
{
    LLog(@"HALLILUYA!!! In MyAddressBook External Change Callback");
    
    [CheckAddressBookChanges reBuildSenderContactList];
}

#pragma mark HASH

- (NSUInteger)toHash:(NSDictionary *)sourseDict
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    for (NSObject *key in [[sourseDict allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        result = prime * result + [key hash];
        result = prime * result + [sourseDict[key] hash];
    }
    return result;
}





//ABAddressBookRevert(notifyAddressBook);
//    notifyAddressBook = ABAddressBookCreate();
//
//    CFArrayRef peopleRefs = ABAddressBookCopyArrayOfAllPeopleInSource(notifyAddressBook, kABSourceTypeLocal);
//
//    CFIndex count = CFArrayGetCount(peopleRefs);
//    NSMutableArray* people = [NSMutableArray arrayWithCapacity:count];
//    for (CFIndex i=0; i < count; i++) {
//        ABRecordRef ref = CFArrayGetValueAtIndex(peopleRefs, i);
//        ABRecordID id_ = ABRecordGetRecordID(ref);
//        TiContactsPerson* person = [[[TiContactsPerson alloc] _initWithPageContext:[context executionContext] recordId:id_ module:context] autorelease];
//        // NSLog(@"name: %@", [person valueForKey:@"firstName"]);
//        // NSLog(@"phone: %@", [person valueForKey:@"phone"]);
//        // NSLog(@"modified: %@", [person valueForKey:@"modified"]);
//        [people addObject:person];
//    }

//    CFRelease(peopleRefs);

//    ABAddressBookRef addressBook = ABAddressBookCreate(); // create address book record
//    ABRecordRef person = ABPersonCreate(); // create a person
//
//    NSString *phone = @"0123456789"; // the phone number to add
//
//    //Phone number is a list of phone number, so create a multivalue
//    ABMutableMultiValueRef phoneNumberMultiValue  = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//    ABMultiValueAddValueAndLabel(phoneNumberMultiValue, phone, kABPersonPhoneMobileLabel, NULL);
//
//    ABRecordSetValue(person, kABPersonFirstNameProperty, @"FirstName" , nil); // first name of the new person
//    ABRecordSetValue(person, kABPersonLastNameProperty, @"LastName", nil); // his last name
//    ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, &anError); // set the phone number property
//    ABAddressBookAddRecord(addressBook, person, nil); //add the new person to the record
//
//    ABRecordRef group = ABGroupCreate(); //create a group
//    ABRecordSetValue(group, kABGroupNameProperty,@"My ChatTypeGroup", &error); // set group's name
//    ABGroupAddMember(group, person, &error); // add the person to the group
//    ABAddressBookAddRecord(addressBook, group, &error); // add the group
//
//
//    ABAddressBookSave(addressBook, nil); //save the record
//
//
//
//    CFRelease(person); // relase the ABRecordRef  variable




@end
