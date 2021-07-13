//
//  CodeDataBaseManager.m
//  SENDER
//
//  Created by Eugene Gilko on 10/8/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "CoreDataBaseManager.h"

static CoreDataBaseManager * instance = nil;

@interface CoreDataBaseManager()

@property (nonatomic, strong) NSManagedObjectContext * parentContext;
@property (nonatomic, strong) NSManagedObjectContext * childContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator * persistentStoreCoordinator;
@property (nonatomic, retain) NSManagedObjectModel * managedObjectModel;

@end

@implementation CoreDataBaseManager

+ (CoreDataBaseManager *)sharedManager
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[CoreDataBaseManager alloc] init];
        [instance initContextObjects];
    });
    
    return instance;
}

- (BOOL)initContextObjects
{
    _parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_parentContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    _childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_childContext setParentContext:_parentContext];
    
    return YES;
}

- (void)saveContext
{
    if ([_childContext hasChanges]) {
        [_childContext performBlock:^{
            NSError * error = nil;
            [_childContext save:&error];
            if(!error){
                
                [self saveMasterContext];
            }
            else {
                 LLog(@"CORE DATA CHILD CONTEXT ERROR : %@", error);
            }
        }];
    }
}

- (void)saveMasterContext {
    
    [_parentContext performBlock:^{
        NSError * error = nil;
        [_parentContext save:&error];
        if(error){
             LLog(@"CORE DATA MASTER CONTEXT ERROR : %@", error);
        }
    }];
}

- (void)deleteObject:(NSManagedObject *)object
{
    if (!object) return;
    
    NSManagedObjectID * moID = [object objectID];
    
    if (!moID) return;
    
    [self.childContext deleteObject:[self.childContext objectWithID:moID]];
    [self saveContext];
}

- (BOOL)deleteAll
{
    NSFetchRequest * dialogsRequest = [[NSFetchRequest alloc] init];
    [dialogsRequest setEntity:[NSEntityDescription entityForName:@"Dialog" inManagedObjectContext:self.childContext]];
    [dialogsRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * dialogs = [self.childContext executeFetchRequest:dialogsRequest error:&error];
    
    for (NSManagedObject * dialog in dialogs) {
        [self deleteObject:dialog];
    }
    
    [self saveContext];
    
    NSFetchRequest *contactsRequest = [[NSFetchRequest alloc] init];
    [contactsRequest setEntity:[NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.childContext]];
    [contactsRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSArray * contacts = [self executeFetchRequest:contactsRequest];
    
    for (NSManagedObject * contact in contacts) {
        [self deleteObject:contact];
    }
    
    [self saveContext];

    return YES;
}

- (NSFetchRequest *)getRequestForObjectWithName:(NSString *)name {
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:self.parentContext]];
    return request;
}


- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName inContex:(NSManagedObjectContext *)context {
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    return [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] inManagedObjectContext:context];
}


- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName {
    
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.childContext];
    return [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] inManagedObjectContext:self.childContext];
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request
{
    NSError * error = nil;
    NSArray * result = [self.parentContext executeFetchRequest:request error:&error];
    if (!result) {
        [self defaultErrorHandler:error];
        result = [NSArray array];
    }
//    [self saveContext];
    return result;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL * modelURL = [SENDER_FRAMEWORK_BUNDLE URLForResource:@"senderBase" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL * storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"senderBase.sqlite"];
    NSError * error = nil;
    
    NSDictionary * options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        
        // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)defaultErrorHandler:(NSError *)error
{
    NSDictionary * userInfo = [error userInfo];
    for (NSArray * detailedError in [userInfo allValues])
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

@end
