//
//  CoreDataFacade.m
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "CoreDataFacade.h"
#import "Dialog.h"
#import "Settings.h"
#import "Contact.h"
#import <SDWebImage/SDImageCache.h>
#import "SenderNotifications.h"
#import "AddressBook.h"
#import "ServerFacade.h"
#import "File.h"
#import "ParamsFacade.h"
#import "ECCWorker.h"
#import "DialogSetting.h"
#import "BarModel.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "MessagesGap.h"
#import "Owner.h"
#import "CompanyCard+CoreDataClass.h"
#import "ChatMember+CoreDataProperties.h"

NSString * userIDFromChatID(NSString * chatID)
{
    NSString * prefix = @"user+";

    if ([chatID hasPrefix:prefix])
        return [chatID substringFromIndex:[prefix length]];
    else
        return nil;
}

NSString * chatIDFromUserID(NSString * userID)
{
    return [NSString stringWithFormat:@"user+%@", userID];
}

void copyNSManagedObjectAttributes(NSManagedObject * source, NSManagedObject * target)
{
    if (![target isKindOfClass:[source class]]) return;

    NSEntityDescription * objectDescription = [NSEntityDescription entityForName:[[source entity] name]
                                                          inManagedObjectContext:[source managedObjectContext]];
    NSDictionary * oldOwnerAttributes = [objectDescription attributesByName];
    for (NSString * attribute in oldOwnerAttributes)
        [target setValue:[source valueForKey:attribute] forKey:attribute];
}

NSURL * applicationDocumentsDirectory()
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

static CoreDataFacade * instance = nil;

@interface CoreDataFacade ()
{
    Dialog * senderChat;
}

@property (nonatomic, retain) NSManagedObjectModel * managedObjectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator * persistentStoreCoordinator;

@property (nonatomic, strong) NSURL * storeURL;
@property (nonatomic, strong) NSURL * managedObjectModelURL;

@end

@implementation CoreDataFacade

+ (CoreDataFacade *)sharedInstance
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSURL * managedObjectModelURL = [SENDER_FRAMEWORK_BUNDLE URLForResource:@"senderBase2" withExtension:@"momd"];
        NSURL * storeURL = [applicationDocumentsDirectory() URLByAppendingPathComponent:@"senderBase2.sqlite"];
        instance = [[CoreDataFacade alloc] initWithStoreURL:storeURL managedObjectModelURL:managedObjectModelURL];
        [instance performHardcoreMigrationIfNecessary];
        [instance deleteRemovedChats];
//        [instance setupSaveNotification];
    });
    
    return instance;
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL managedObjectModelURL:(NSURL *)managedObjectModelURL
{
    self = [super init];
    if (self)
    {
        self.managedObjectModelURL = managedObjectModelURL;
        self.storeURL = storeURL;
    }
    return self;
}

- (void)performHardcoreMigrationIfNecessary
{
    //1. Checking for old store. No old store - no migration.
    NSURL * oldStoreURL = [applicationDocumentsDirectory() URLByAppendingPathComponent:@"senderBase.sqlite"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldStoreURL.path])
    {
        //2. If there is a new store, we shouldn't change entities in new store. Just delete the old one
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.storeURL.path])
        {
            NSURL *oldModelURL = [SENDER_FRAMEWORK_BUNDLE URLForResource:@"senderBase" withExtension:@"momd"];
            CoreDataFacade *oldDataFacade = [[CoreDataFacade alloc] initWithStoreURL:oldStoreURL
                                                               managedObjectModelURL:oldModelURL];

            //3. We only need to copy attributes of owner and settings. We'll get everything else after sync
            Owner *oldOwner = [oldDataFacade getOwner];
            Owner *newOwner = [self getOwner];

            copyNSManagedObjectAttributes(oldOwner, newOwner);

            Settings * oldSettings = oldOwner.settings;
            Settings * newSettings = newOwner.settings;
            copyNSManagedObjectAttributes(oldSettings, newSettings);

            //4. Resetting ownerUDIDString
            self.ownerUDIDString = newOwner.ownerID;

            //5. We need to repeat sync, so we change authorization state if app has already done it before
            if (oldOwner.authorizationState == OwnerAuthorizationStateAuthorizedAsNewUser ||
                    oldOwner.authorizationState == OwnerAuthorizationStateAuthorized ||
                    oldOwner.authorizationState == OwnerAuthorizationStateNotAuthorized)
                newOwner.authorizationState = oldOwner.authorizationState;
            else
                newOwner.authorizationState = OwnerAuthorizationStateSyncedWallet;

            [self saveContext];
        }
        //6. Deleting old store. We don't handle error, because if deleting was unsuccessful,
        // CoreDataFacade will try to delete old store next time this method is called
        NSError * error;
        [[NSFileManager defaultManager] removeItemAtURL:oldStoreURL error:&error];
    }
}

- (void)deleteRemovedChats
{
    NSFetchRequest *dialogsRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * dialogDescription = [NSEntityDescription entityForName:@"Dialog"
                                                          inManagedObjectContext:self.managedObjectContext];
    [dialogsRequest setEntity:dialogDescription];
    NSPredicate * removedPredicate = [NSPredicate predicateWithFormat:@"state = %@", @(ChatStateRemoved)];
    [dialogsRequest setPredicate:removedPredicate];
    [dialogsRequest setIncludesPropertyValues:YES];

    NSError *error;
    NSArray *dialogs = [self.managedObjectContext executeFetchRequest:dialogsRequest error:&error];

    BOOL(^shouldDeleteP2PChat)(Dialog *) = ^BOOL(Dialog * chat) {
        if (![[chat.p2pContact memberRepresentations]count])
            return YES;

        if ([[chat.p2pContact memberRepresentations] count] == 1)
        {
            ChatMember * memberRepresentation = [[chat.p2pContact memberRepresentations] anyObject];
            return [memberRepresentation.chat isEqual:chat];
        }
        else
        {
            return NO;
        }
    };

    for (Dialog *dialog in dialogs)
    {
        if (dialog.isGroup || shouldDeleteP2PChat(dialog))
            [self.managedObjectContext deleteObject:dialog];
    }

    [self saveContext];
}

- (BOOL)deleteAll
{
    senderChat = nil;
    NSFetchRequest *dialogsRequest = [[NSFetchRequest alloc] init];
    [dialogsRequest setEntity:[NSEntityDescription entityForName:@"Dialog" inManagedObjectContext:self.managedObjectContext]];
    [dialogsRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *dialogs = [self.managedObjectContext executeFetchRequest:dialogsRequest error:&error];
    
    for (NSManagedObject *dialog in dialogs) {
        [self.managedObjectContext deleteObject:dialog];
    }
    
    [self saveContext];
    
    NSFetchRequest *contactsRequest = [[NSFetchRequest alloc] init];
    [contactsRequest setEntity:[NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.managedObjectContext]];
    [contactsRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSArray *contacts = [self.managedObjectContext executeFetchRequest:contactsRequest error:&error];
    
    for (NSManagedObject * contact in contacts) {
        [self.managedObjectContext deleteObject:contact];
    }
    
    [self saveContext];
    
    return YES;
}

- (BOOL)clearOwnerModel
{
    self.ownerUDIDString = nil;

    if ([self deleteAll])
    {
        [[self getOwner] deleteMainWalletWithError:nil];
        [self deleteManagedObject:[self getOwner]];
        self.owner = nil;
        [self saveContext];
    }
    
    return YES;
}

- (void)cleanFullVersionData
{
    [[self getOwner] deleteMainWalletWithError:nil];

    NSArray<Dialog *> * chats = [self getDialogs];
    for (Dialog * chat in chats) {
        if (chat.chatType != ChatTypeCompany)
            [self deleteManagedObject:chat];
    }

    NSArray *cont = [self findAllWithName:@"Contact" sortedBy:@"name" ascending:YES withPredicate:nil];

    for (Contact *object in cont)
    {
        if (![object.isCompany boolValue])
        {
            [[self getOwner] removeContactsObject:object];
            [self deleteManagedObject:object];
        }
    }

    [self saveContext];

    [[SenderCore sharedCore].interfaceUpdater chatsWereChanged:chats];
}


- (void)setupSaveNotification
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification* note) {
                                                      NSManagedObjectContext * moc = self.managedObjectContext;
                                                      if (note.object != moc) {
                                                          [moc performBlock:^(){
                                                              [moc mergeChangesFromContextDidSaveNotification:note];
                                                          }];
                                                      }
                                                  }];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.managedObjectModelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self storeURL];
    NSError *error = nil;
    
    NSDictionary * options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                               NSInferMappingModelAutomaticallyOption: @YES};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        
        // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Service

- (void)saveContext
{
    NSManagedObjectContext * managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        @try {
            
            if ([managedObjectContext hasChanges]) {
                
                [managedObjectContext performBlock:^{
                    NSError *error = nil;
                    [managedObjectContext save:&error];
                    if (error) {
                       // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    }
                    else {
                        // NSLog(@"COREDATA SAVE DONE !!!!!! =================== !!!!");
                    }

                }];
            }
        }
        @catch (NSException *exception) {
            // NSLog(@"SaveChanges exception %@", exception);
        }
    };
}

- (void)saveContextSynchronously
{
    NSManagedObjectContext * managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        @try {

            if ([managedObjectContext hasChanges]) {

                [managedObjectContext performBlockAndWait:^{
                    NSError *error = nil;
                    [managedObjectContext save:&error];
                    if (error) {
                        // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    }
                    else {
                        // NSLog(@"COREDATA SAVE DONE !!!!!! =================== !!!!");
                    }

                }];
            }
        }
        @catch (NSException *exception) {
            // NSLog(@"SaveChanges exception %@", exception);
        }
    };
}

- (void) defaultErrorHandler:(NSError *)error
{
    NSDictionary *userInfo = [error userInfo];
    for (NSArray *detailedError in [userInfo allValues])
    {
        if ([detailedError isKindOfClass:[NSArray class]])
        {
            for (NSError *e in detailedError)
            {
                if ([e respondsToSelector:@selector(userInfo)])
                {
                    // NSLog(@"Error Details: %@", [e userInfo]);
                }
                else
                {
                    // NSLog(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            // NSLog(@"Error: %@", detailedError);
        }
    }
    // NSLog(@"Error Message: %@", [error localizedDescription]);
    // NSLog(@"Error Domain: %@", [error domain]);
    // NSLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

- (void)deleteManagedObject:(NSManagedObject *)object
{
    if (object)
        [self.managedObjectContext deleteObject:object];
}

- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName
{
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    return [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] inManagedObjectContext:self.managedObjectContext];
}

- (NSInteger)executeCountFetchRequest:(NSFetchRequest *)request
{
    @synchronized(self) {
        NSInteger count = -1;
        NSError *error = nil;
        NSArray * result = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (!result) {
            [self defaultErrorHandler:error];
        } else {
            count = [[result firstObject] integerValue];
        }
        return count;
    }
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request {

    @synchronized(self) {
        NSError *error = nil;
        NSArray * result = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (!result) {
            [self defaultErrorHandler:error];
            result = [NSArray array];
        }
        return result;
    }
}

- (NSFetchRequest *)getRequestForObjectWithName:(NSString *)name {
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext]];
    return request;
}

- (NSManagedObject *)findFirstObjectWithName:(NSString *)name byProperty:(NSString *)property withValue:(id)value {
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value]];
    return [self executeFetchRequestAndReturnFirstObject:request];
}

- (NSManagedObject *)executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request {
    [request setFetchLimit:1];
    
    NSArray *results = [self executeFetchRequest:request];
    if ([results count] == 0)
    {
        return nil;
    }
    return [results objectAtIndex:0];
}

- (NSArray *)getSortDescriptorsBy:(NSString *)sortTerm ascending:(BOOL)ascending {
    NSMutableArray * sortDescriptors = [[NSMutableArray alloc] init];
    NSArray * sortKeys = [sortTerm componentsSeparatedByString:@","];
    for (NSString * sortKey in sortKeys)
    {
        if ([sortKey isEqualToString: @"isOnline"]) {
            NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:NO];
            [sortDescriptors addObject:sortDescriptor];
        }
        else {
            NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
            [sortDescriptors addObject:sortDescriptor];
        }
    }
    return sortDescriptors;
}

- (NSArray *) findAllWithName:(NSString *)name {
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    return [self executeFetchRequest:request];
}

- (NSArray *) findAllWithName:(NSString *)name sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
    return [self findAllWithName:name sortedBy:sortTerm ascending:ascending withPredicate:nil];
}

- (NSInteger)countAllWithName:(NSString *)name
                withPredicate:(NSPredicate *)searchTerm
        includePendingChanges:(BOOL)includePending
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];

    [request setIncludesPendingChanges:includePending];
    [request setResultType:NSCountResultType];
    if (searchTerm) [request setPredicate:searchTerm];

    return [self executeCountFetchRequest: request];
}

- (NSArray *)findAllWithName:(NSString *)name
                     sortedBy:(NSString *)sortTerm
                    ascending:(BOOL)ascending
                withPredicate:(NSPredicate *)searchTerm
        includePendingChanges:(BOOL)includePending
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];

    if (searchTerm) [request setPredicate:searchTerm];
    [request setIncludesPendingChanges:includePending];
    NSArray* sortDescriptors = [self getSortDescriptorsBy:sortTerm ascending:ascending];
    [request setSortDescriptors:sortDescriptors];
    
    return [self executeFetchRequest:request];
}

- (NSArray *)findAllWithName:(NSString *)name
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
               withPredicate:(NSPredicate *)searchTerm
{
    return [self findAllWithName:name
                        sortedBy:sortTerm
                       ascending:ascending
                   withPredicate:searchTerm
           includePendingChanges:NO];
}

- (NSArray *)findObjectsWithName:(NSString *)name byProperty:(NSString *)property withValueLike:(NSString *)value
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", property, value]];
    return [self executeFetchRequest:request];
}

#pragma mark - Get data

- (NSArray<Dialog *> *)getUnreadChats
{
    NSPredicate * predicateUnread = [NSPredicate predicateWithFormat:@"unreadCount > %@", @"0"];
    return [self findAllWithName:@"Dialog" sortedBy:@"name" ascending:YES withPredicate:predicateUnread];
}

- (NSString *)ownerUDID
{
    if (!self.ownerUDIDString) {
        [self getOwner];
        return self.ownerUDIDString;
    }
    
    return self.ownerUDIDString;
}

- (Owner *)getOwner
{
    if (self.owner) {
        return self.owner;
    }
    
    NSArray * owners = [self findAllWithName:@"Owner"];
    if(owners.count == 1)
    {
        Owner * temp = (Owner *)[owners firstObject];
        self.ownerUDIDString = temp.ownerID;
        self.owner = temp;
        return temp;
    }
    else if(owners.count > 1)
    {
        NSMutableArray * mutOwners = [NSMutableArray arrayWithArray:owners];
        while (owners.count > 1) {
            Owner * temp = mutOwners.lastObject;
            [mutOwners removeLastObject];
            [self deleteManagedObject:temp];
        }
        
        Owner * temp = (Owner *)[mutOwners firstObject];
        temp.uid = temp.objectID.description;
        
        self.ownerUDIDString = temp.ownerID;
        self.owner = temp;
        return temp;
    }
    else
    {
        Owner * temp = (Owner *)[self getNewObjectWithName:@"Owner"];
        temp.uid = temp.objectID.description;
        self.ownerUDIDString = temp.ownerID;
        temp.name = @"New User Name";
        temp.desc = @"User description";
        temp.settings = (Settings *)[self getNewObjectWithName:@"Settings"];
        temp.settings.sendRead = @(YES);
        temp.settings.sounds = @(YES);
        temp.settings.notificationsSound = @(YES);
        temp.settings.location = @(YES);
        temp.settings.language = [[NSLocale preferredLanguages] firstObject];
        [self saveContext];
        
        NSString * defaultTheme = [[NSUserDefaults standardUserDefaults] objectForKey:@"StyleApp"];
        if ( !defaultTheme )
        {
            defaultTheme = @"bright";
        }
        temp.settings.theme = defaultTheme;
        [[NSUserDefaults standardUserDefaults] setObject:temp.settings.theme forKey:@"StyleApp"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        self.owner = temp;
        return temp;
    }
}

#pragma mark Setting

- (BOOL)checkForDialogSetting:(Dialog *)dialog
{
    if (!dialog.chatSettings && dialog.managedObjectContext) {
        dialog.chatSettings = (DialogSetting *)[self getNewObjectWithName:@"DialogSetting"];
        [dialog.dialogSetting initDefaultValue];
    }
    return YES;
}

- (void)updateDialogSetting:(Dialog *)dialog withJsonData:(NSDictionary *)jsonData
{
    [dialog.dialogSetting dialogSetting:jsonData[@"model"]];
}

- (nullable Dialog *)dialogWithChatIDIfExist:(NSString *)chat
{
    return (Dialog *)[self findFirstObjectWithName:@"Dialog" byProperty:@"chatID" withValue:chat];
}

- (Message *)newMessageModel
{
    return (Message *)[self getNewObjectWithName:@"Message"];
}

- (Contact * _Nullable)selectContactById:(NSString *)userId
{
    return (Contact *)[self findFirstObjectWithName:@"Contact" byProperty:@"userID" withValue:userId];
}

- (Contact *)contactWithLocalID:(NSString *)localID
{
    return (Contact *)[self findFirstObjectWithName:@"Contact" byProperty:@"localID" withValue:localID];
}

- (Message *)messageById:(NSString *)messageId
{
    return (Message *)[self findFirstObjectWithName:@"Message" byProperty:@"moId" withValue:messageId];;
}

- (Dialog *)getSenderChat
{
    if (!senderChat)
    {
        NSString * senderChatID = [[self getOwner] senderChatId];
        senderChat = [self dialogWithChatIDIfExist:senderChatID];
    }
    return senderChat;
}

- (NSArray<Contact *> *)getUsers
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"userID != %@", @"0"];
    return [self findAllWithName:@"Contact" sortedBy:@"name" ascending:YES withPredicate:predicate];
}

- (NSArray<Contact *> *)getAllContacts
{
    return [self findAllWithName:@"Contact" sortedBy:@"name" ascending:YES withPredicate:nil];
}

- (NSArray *)getBlockedChats
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"chatSettings.blockChat == %@", @1];
    return [self findAllWithName:@"Dialog"
                        sortedBy:@"name"
                       ascending:YES
                   withPredicate:predicate
           includePendingChanges:YES];
}

- (NSInteger)getBlockedContactsCount
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"chatSettings.blockChat == %@", @1];
    return [self countAllWithName:@"Dialog" withPredicate:predicate includePendingChanges:YES];
}

- (NSArray *)getOperatedCompaniesChats
{
    NSPredicate * predicateOpCompanies = [NSPredicate predicateWithFormat:@"type = %@", @"oper"];
    return [self findAllWithName:@"Dialog" sortedBy:@"name" ascending:YES withPredicate:predicateOpCompanies];
}

- (NSArray *)getMyOperatedList
{
    NSMutableArray * allOperatorsDialogs = [[NSMutableArray alloc] init];
    
    if (self.getOwner.companies) {
        
        NSArray * companies = [[ParamsFacade sharedInstance] arrayFromNSData:self.getOwner.companies];
    
        if (companies.count) {
            
            NSMutableArray * allDialogs = [[NSMutableArray alloc] initWithArray:[self getOperatedCompaniesChats]];
            
            for (NSString * companyID in companies) {
                
                Contact * companyContact = (Contact *)[self findFirstObjectWithName:@"Contact" byProperty:@"userID" withValue:companyID];
                
                if (companyContact) {
                    
                    NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
                    
                    [result setObject:companyContact forKey:@"companyOp"];
                    
                    NSMutableArray * allDialogchats = [[NSMutableArray alloc] init];
                    
                    for (Dialog * dialog in allDialogs) {
                        
                        if ([dialog.companyID isEqualToString:companyContact.userID]) {
                            [allDialogchats addObject:dialog];
                        }
                    }
                    
                    [allDialogs removeObjectsInArray:allDialogchats];
                    
                    [result setObject:allDialogchats forKey:@"chatsOp"];
                    
                    [allOperatorsDialogs addObject:result];
                }
            }
        }
    }
    
    return allOperatorsDialogs;
}

- (NSArray *)getChats
{
    return  [self findAllWithName:@"Dialog" sortedBy:@"name" ascending:YES withPredicate:nil];
}

- (NSArray *)getP2PChats
{
    NSString * p2pTypeString = stringFromChatType(ChatTypeP2P);
    NSString * companyTypeString = stringFromChatType(ChatTypeCompany);
    NSPredicate * predicateType =  [NSPredicate predicateWithFormat:@"type = %@ || type = %@", p2pTypeString, companyTypeString];
    return [self getPersistentChatsWithPredicate:predicateType];
}

- (NSArray *)getChatsWithUsers
{
    NSString * typeString = stringFromChatType(ChatTypeP2P);
    NSPredicate * predicateType =  [NSPredicate predicateWithFormat:@"type = %@", typeString];
    return [self getPersistentChatsWithPredicate:predicateType];
}

- (NSArray<Dialog *> *)getCompanyChats
{
    NSString * typeString = stringFromChatType(ChatTypeCompany);
    NSPredicate * predicateType =  [NSPredicate predicateWithFormat:@"type = %@", typeString];
    return [self getPersistentChatsWithPredicate: predicateType];
}

- (NSArray<Dialog *> *)getPersistentChatsWithPredicate:(NSPredicate *)predicate
{
    NSNumber * removedState = @(ChatStateRemoved);
    NSNumber * undefinedState = @(ChatStateUndefined);
    NSPredicate * persistentChatPredicates = [NSPredicate predicateWithFormat:@"state != %@ && state != %@",
                    removedState, undefinedState];
    NSArray * subPredicates = @[persistentChatPredicates, predicate];
    NSCompoundPredicate * compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    return [self findAllWithName:@"Dialog" sortedBy:@"name" ascending:YES withPredicate:compoundPredicate];
}

- (NSArray *)getDialogs
{
    return [self findAllWithName:@"Dialog" sortedBy:@"lastMessageTime" ascending:NO];
}

#pragma mark - Contacts

- (Contact *)getNewContactWithUserID:(NSString *)userID
{
    Contact * temp = (Contact *)[self getNewObjectWithName:@"Contact"];
    temp.userID = userID;
    [self.getOwner addContactsObject:temp];
    return temp;
}

- (void)setOwnerInfo:(NSDictionary *)userInfo
{
    Owner * contact = [self getOwner];
    if (contact) {
        if (((NSString *)userInfo[@"userId"]).length) {
            contact.ownerID = userInfo[@"userId"];
            contact.uid = contact.ownerID;
            self.ownerUDIDString = contact.ownerID;
        }
        
        if (((NSString *)userInfo[@"name"]).length)
            contact.name = userInfo[@"name"];
        
        if (((NSString *)userInfo[@"description"]).length)
            contact.desc = userInfo[@"description"];
        else
            contact.desc = @"";
        
        if (userInfo[@"companies"]) {
            
            NSArray * compArray = userInfo[@"companies"];
            if (compArray.count) {
                contact.companies = [[ParamsFacade sharedInstance] nSdateFromArray:compArray];
            }
        }
        
        NSArray * contacts = userInfo[@"contacts"];
        if (contacts && contacts.count && [contacts[0][@"type"] isEqualToString:@"phone"])
            contact.numberPhone = contacts[0][@"value"];
        
        if (userInfo[@"photo"])
            contact.ownimgurl = [userInfo[@"photo"] isKindOfClass:[NSString class]] ? (NSString *)userInfo[@"photo"] : nil;

        [[SenderCore sharedCore].interfaceUpdater ownerWasChanged:contact];
//        if ([userInfo[@"btcAddr"] length])
//        {
//            NSString * test = [[CoreDataFacade sharedInstance].getOwner getMainWallet:nil].rootKeyPublic;
//                
//            if ([userInfo[@"btcAddr"] isEqualToString:test])
//                contact.bwalletstate = @"ready";
//            else
//                contact.bwalletstate = @"needImport";
//        }
//        else
//        {
//            contact.bwalletstate = @"empty";
//        }
    }
}

- (void)setOwnerImageData:(NSData *)data
{
    Owner * owner = [self getOwner];
    [self saveContext];
    [[SenderCore sharedCore].interfaceUpdater ownerWasChanged:owner];
}

#pragma mark - Dialogs

- (void)clearAllHistory
{
    NSArray * dialogs = [self getDialogs];
    for (Dialog * dialogToClear in dialogs) {
        for (Message * msg in dialogToClear.messages)
            [[CoreDataFacade sharedInstance]deleteManagedObject:msg];
        for (MessagesGap * gap in dialogToClear.gaps)
            [[CoreDataFacade sharedInstance]deleteManagedObject:gap];
        dialogToClear.unreadCount = @0;
    }
    [self saveContext];
    [SENDER_SHARED_CORE.interfaceUpdater chatsWereChanged:dialogs];
}

#pragma mark - Messages

- (void)setStatus:(NSString *)status forMessage:(NSString *)messageId
{
    Message * temp = (Message *)[self findFirstObjectWithName:@"Message" byProperty:@"moId" withValue:messageId];
    if (temp) {
        temp.deliver = status;
        [SENDER_SHARED_CORE.interfaceUpdater messagesWereUpdated:@[temp]];
    }
}

- (void)setNewPacketID:(NSString *)packetID
                  moID:(NSString *)moID
       andCreationTime:(NSDate *)creation
            forMessage:(Message *)message
{
    if (message)
    {
        if (packetID)
            message.packetID = ([packetID isKindOfClass:[NSString class]]) ? packetID : [packetID description];

        if (moID)
            message.moId = ([moID isKindOfClass:[NSString class]]) ? moID : [moID description];
       
        if (creation)
            message.created = creation;
        else if (!message.created)
            message.created = [NSDate date];
    }
}

- (void)setNewPacketID:(NSString *)packetID
            forMessage:(Message *)message
{
    [self setNewPacketID:packetID moID:nil andCreationTime:nil forMessage:message];
}

- (Message *)writeMessageWithText:(NSString *)text inChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = @"";
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"text":text,@"pkey":@""}];
    temp.deliver = @"ND";
    temp.type = @"TEXT";

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeMessageWithStickerID:(NSString *)stickerID inChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = @"";
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.data =  [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"id": stickerID}];
    temp.deliver = @"ND";
    temp.type = @"STICKER";

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeVoiceMessageInChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = @"";
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.deliver = @"ND";
    temp.type = @"AUDIO";
    temp.formId = @"audio";
    temp.robotId = @"routerobot";
    temp.companyId = @"sender";

    temp.file = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
    temp.file.type = @"mp3";

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeVibroMessageInChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = @"";
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.data =  [[ParamsFacade sharedInstance] NSDataFromNSDictionary:@{@"oper": @"begin"}];
    temp.deliver = @"ND";
    temp.type = @"VIBRO";

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeImageMessageWithLocalURL:(NSString *)localURL inChat:(Dialog *)chat
{
    if(!chat.chatID)
        return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = [temp.objectID description];
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.deliver = @"ND";
    temp.type = @"IMAGE";
    temp.formId = @"image";
    temp.robotId = @"routerobot";
    temp.companyId = @"sender";

    temp.file = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
    temp.file.type = @"jpg";
    temp.file.url = localURL;
    temp.file.localUrl = localURL;

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeVideoMessageWithLocalURL:(NSString *)localURL
                             videoDuration:(NSTimeInterval)duration
                                    inChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = [temp.objectID description];
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.deliver = @"ND";
    temp.type = @"VIDEO";
    temp.formId = @"";
    temp.robotId = @"routerobot";
    temp.companyId = @"sender";

    temp.file = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
    temp.file.type = @"mp4";
    temp.file.url = localURL;
    temp.file.localUrl = localURL;

    NSString * durationDescription = [NSString stringWithFormat:@"%.2f",duration];
    durationDescription = [durationDescription stringByReplacingOccurrencesOfString:@"." withString:@":"];
    temp.file.desc = durationDescription;


    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];

    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (Message *)writeLocationMessageWithData:(NSDictionary *)data inChat:(Dialog *)chat
{
    if(!chat.chatID) return nil;

    Message * temp = (Message *)[self getNewObjectWithName:@"Message"];
    temp.linkID = [temp.objectID description];
    temp.chat = chat.chatID;
    temp.fromId = self.ownerUDIDString;
    temp.encrypted = @(NO);
    temp.deliver = @"ND";
    temp.type = @"SELFLOCATION";
    temp.classRef = data[@"class"];

    temp.file = (File *)[[CoreDataFacade sharedInstance] getNewObjectWithName:@"File"];
    temp.file.type = @"jpg";
    temp.file.localUrl = nil;

    temp.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:data];
    temp.modelData = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:data];

    [self setNewPacketID:[temp.objectID description]
                    moID:[temp.objectID description]
         andCreationTime:[NSDate date]
              forMessage:temp];
    
    [chat addMessagesObject:temp];

    [[SenderCore sharedCore].interfaceUpdater messagesWereAdded:@[temp]];

    return temp;
}

- (void)setUploadUrl:(NSString *)url toMessage:(NSString *)messageId
{
    Message * message = (Message *)[self findFirstObjectWithName:@"Message" byProperty:@"moId" withValue:messageId];
    message.file.url = url;
    message.file.isDownloaded = @YES;
}

- (void)setLocalUrl:(NSString *)url toMessage:(NSString *)messageId
{
    Message * message = (Message *)[self findFirstObjectWithName:@"Message" byProperty:@"moId" withValue:messageId];
    message.file.localUrl = url;
    message.file.isDownloaded = @YES;
}

- (BarModel * _Nonnull)senderBar
{
    MWChatBuildManager * chatBuildManager = [MWChatBuildManager buildDefaultChatBuildManager];
    Dialog * senderChat = [chatBuildManager chatWithChatID:[[self getOwner] senderChatId] isNewChat:nil];
    BarModel * sendBar = senderChat.sendBar;
    if (![sendBar.barItems count])
    {
        MWSendBarItemCreator * itemCreator = [[MWSendBarItemCreator alloc] init];
        MWSendBarItemBuilder * itemBuilder = [[MWSendBarItemBuilder alloc] init];
        MWSendBarItemBuildManager * itemBuildManager = [[MWSendBarItemBuildManager alloc] initWithSendBarItemCreator:itemCreator
                                                                                                  sendBarItemBuilder:itemBuilder];
        MWSendBarCreator * barCreator = [[MWSendBarCreator alloc] init];
        MWSendBarBuilder * barBuilder = [[MWSendBarBuilder alloc] initWithSendBarItemBuildManager:itemBuildManager];
        MWSendBarBuildManager * barBuildManager = [[MWSendBarBuildManager alloc] initWithSendBarCreator:barCreator
                                                                                         sendBarBuilder:barBuilder];

        NSDictionary * barDict = [NSDictionary dictionaryWithContentsOfFile:[SENDER_FRAMEWORK_BUNDLE pathForResource:@"DefaultBar"
                                                                                                              ofType:@"plist"]];
        BarModel * localSendBar = [barBuildManager sendBarWithDictionary:barDict[@"bar"]];
        senderChat.sendBar = localSendBar;
    }
    return senderChat.sendBar;
}

- (MessagesGap *)addGapWithStartPacketID:(NSInteger)startPacketID
                             endPacketID:(NSInteger)endPacketID
                            creationTime:(NSTimeInterval)creationTime
                                  toChat:(nonnull Dialog *)chat
{
    MessagesGap * gap = (MessagesGap *)[self getNewObjectWithName:@"MessagesGap"];
    gap.startPacketID = @(startPacketID);
    gap.endPacketID = @(endPacketID);
    gap.created = [NSDate dateWithTimeIntervalSince1970:(creationTime / 1000)];
    [chat addGapsObject:gap];
    return gap;
}

- (CompanyCard * _Nonnull)createCompanyCard
{
    return (CompanyCard *)[self getNewObjectWithName:@"CompanyCard"];
}

@end