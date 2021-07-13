//
//  AddressBook.m
//  SENDER
//
//  Created by Nick Gromov on 10/3/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "AddressBook.h"

#import "NSString(common_addition).h"
#import "CoreDataFacade.h"
#import "Owner.h"

#import <libPhoneNumber_iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber_iOS/NBPhoneNumber.h>

@implementation AddressBook

- (void)loadContactsNormalized:(BOOL)normalize
{
    isNeedNormalize = normalize;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    [self getContactsWithAddressBook:addressBook];
    
//    __block BOOL accessGranted = NO;
    
//    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
//        accessGranted = granted;
//        
//        if (accessGranted) {
//            
//        }
//    });
}

- (BOOL)requestAddressBookAccess
{
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

    __block BOOL accessGranted = NO;
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else {
        accessGranted = YES;
    }
    return accessGranted;
}

- (void)getContactsWithAddressBook:(ABAddressBookRef )addressBook {
    
    contactList = [[NSMutableArray alloc] init];
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    
    for (int i=0; i < nPeople; i++) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
        NSDictionary * dOfPerson = [self contactDictionaryFromRef:ref];
        if (dOfPerson) {
            [contactList addObject:dOfPerson];
        }
    }
}

ABRecordID ABRecordGetRecordID (
        ABRecordRef record
);

- (NSDictionary *)contactDictionaryFromRef:(ABRecordRef)ref
{
    NSMutableDictionary * dOfPerson = [NSMutableDictionary dictionary];
//    NSMutableString * stringForHash = [NSMutableString string];
    
    ABMultiValueRef phones =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty));
    
    CFStringRef firstName, lastName;
    
    firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
    lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
    
    NSString * firstNameString = (NSString *)CFBridgingRelease(firstName);
    NSString * lastNameString = (NSString *)CFBridgingRelease(lastName);
    
    NSMutableString * name = [NSMutableString stringWithString:firstNameString.length ? firstNameString : @""];
    if(lastName)
        [name appendString:[NSString stringWithFormat:@" %@",lastNameString]];
    
    if (!name.length) {
        return nil;
    }
//    [stringForHash appendString:name];
    [dOfPerson setObject:name forKey:@"name"];
    ABRecordID recordID = ABRecordGetRecordID(ref);
    NSString * recordIdString = [NSString stringWithFormat:@"%d",recordID];
    [dOfPerson setObject:recordIdString forKey:@"localID"];
//    [dOfPerson setObject:@"false" forKey:@"is_company"];
  
    NSMutableArray * devs = [NSMutableArray array];
    //For Email ids
  
//    ABMutableMultiValueRef eMail  = ABRecordCopyValue(ref, kABPersonEmailProperty);
//    if(ABMultiValueGetCount(eMail) > 0) {
//        //[dOfPerson setObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0) forKey:@"email"];
//        NSMutableDictionary * phone = [NSMutableDictionary dictionary];
//        phone[@"valueRaw"] = (__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0);
////        phone[@"value"] = (__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0);
//        phone[@"type"] = @"email";
//        [stringForHash appendString:phone[@"valueRaw"]];
//        [devs addObject:phone];
//    }
    
    //For Phone number
    NSString * mobileLabel;
    
    for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++)
    {
//        NSMutableDictionary * phone = [NSMutableDictionary dictionary];
        mobileLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phones, i);
        
        NSString * clearKey =  [mobileLabel stringByReplacingOccurrencesOfString:@"_$!<" withString:@""];
        clearKey =  [clearKey stringByReplacingOccurrencesOfString:@">!$_" withString:@""];
        
        __weak NSString * phoneNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i);
        
        phoneNumber  = [phoneNumber stringByReplacingOccurrencesOfString:@"[^0-9]"
                                                              withString:@""
                                                                 options:NSRegularExpressionSearch
                                                                   range:NSMakeRange(0, [phoneNumber length])];
        
//        phone[@"value"] = isNeedNormalize ? [self analizePhoneNumber:phoneNumber] : phoneNumber;
//        phone[@"valueRaw"] = phoneNumber;
//        phone[@"type"] = @"phone";
//        [stringForHash appendString:phoneNumber];
        
        [devs addObject:phoneNumber];
        
//        if (devs.count > 0) {
//            [dOfPerson setObject:devs forKey:@"contacts"];
//        }
//        else {
//            return nil;
//        }
    }
    
    if (devs.count > 0) {
//        [dOfPerson setObject:devs forKey:@"contacts"];
        [dOfPerson setObject:devs forKey:@"phones"];
    }
    else {
        return nil;
    }
    
//    NSUInteger hash = stringForHash.hash;
////    [dOfPerson setObject:[NSString stringWithFormat:@"%lu",(unsigned long)hash] forKey:@"ref"];
//    [dOfPerson setObject:[NSString stringWithFormat:@"%lu",(unsigned long)hash] forKey:@"clientRef"];
//
//    
//    if (!isNeedNormalize && ABPersonHasImageData(ref)) {
//        NSData * imgData = nil;
//        imgData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(ref, kABPersonImageFormatThumbnail);
//        if (!imgData) {
//            imgData = (__bridge NSData *)ABPersonCopyImageData(ref);
//        }
//        if (imgData) {
//            [dOfPerson setObject:imgData forKey:@"imgData"];
//        }
//    }
    
    return dOfPerson;
}

- (NSArray<NSDictionary *> *)getContacts
{
    return contactList ? contactList : @[];
}

- (NSDictionary *)getPersonDictByHash:(NSString *)hash
{
    NSArray * result = [contactList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"clientRef == %@", hash]];
    if (result.count) {
        return result[0];
    }
    return nil;
}


@end
