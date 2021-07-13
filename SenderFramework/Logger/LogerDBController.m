//
//  LogerDBController.m
//  SENDER
//
//  Created by Eugene Gilko on 12/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "LogerDBController.h"
#import "ServerFacade.h"
#import "CometController.h"
#import "LogEvent.h"
#import "Owner.h"
#import <SenderFramework/SenderFramework-Swift.h>

static LogerDBController * instance = nil;

@interface LogerDBController()

@property (nonatomic, retain) NSManagedObjectModel * managedObjectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator * persistentStoreCoordinator;

@end

@implementation LogerDBController

+ (LogerDBController *)sharedCore
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[LogerDBController alloc] init];
    });
    
    return instance;
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
    NSURL *modelURL = [SENDER_FRAMEWORK_BUNDLE URLForResource:@"serviceDB" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"serviceDB.sqlite"];
    ;
    NSError *error = nil;
    
    NSDictionary * options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        
        // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Service

- (void)deleteManagedObject:(NSManagedObject *)object
{
    if (object) {
        [self.managedObjectContext deleteObject:object];
    }
}

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
                        
                    }
                }];
            }
        }
        @catch (NSException *exception) {
            
        }
    };
}

- (void)defaultErrorHandler:(NSError *)error
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
                    
                }
                else
                {
                    NSLog(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            NSLog(@"Error: %@", detailedError);
        }
    }
    NSLog(@"Error Message: %@", [error localizedDescription]);
    NSLog(@"Error Domain: %@", [error domain]);
    NSLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request
{
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

#pragma mark CoreData funcs

- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName
{
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    return [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] inManagedObjectContext:self.managedObjectContext];
}

- (NSFetchRequest *)getRequestForObjectWithName:(NSString *)name
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext]];
    return request;
}

- (NSManagedObject *)findFirstObjectWithName:(NSString *)name byProperty:(NSString *)property withValue:(id)value
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value]];
    return [self executeFetchRequestAndReturnFirstObject:request];
}

- (NSManagedObject *)findObjectWithName:(NSString *)name
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    return [self executeFetchRequestAndReturnFirstObject:request];
}

- (NSManagedObject *)executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
    [request setFetchLimit:1];
    
    NSArray *results = [self executeFetchRequest:request];
    if ([results count] == 0)
    {
        return nil;
    }
    return [results objectAtIndex:0];
}

- (NSArray *)findAllWithName:(NSString *)name
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    return [self executeFetchRequest:request];
}

- (NSArray *)findAllWithName:(NSString *)name sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
    return [self findAllWithName:name sortedBy:sortTerm ascending:ascending withPredicate:nil];
}

- (NSArray *)findAllWithName:(NSString *)name sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm
{
    NSFetchRequest *request = [self getRequestForObjectWithName:name];
    
    if (searchTerm)
        [request setPredicate:searchTerm];
    
    NSArray* sortDescriptors = [self getSortDescriptorsBy:sortTerm ascending:ascending];
    
    [request setSortDescriptors:sortDescriptors];
    
    return [self executeFetchRequest:request];
}

- (NSArray *)getSortDescriptorsBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
    NSMutableArray * sortDescriptors = [[NSMutableArray alloc] init];
    NSArray * sortKeys = [sortTerm componentsSeparatedByString:@","];
    
    for (NSString * sortKey in sortKeys)
    {
        NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
        [sortDescriptors addObject:sortDescriptor];
    }
    
    return sortDescriptors;
}

#pragma mark user defined metods =============================================================================
#pragma mark =================================================================================================

- (void)addLogEvent:(NSDictionary *)eventData
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * model = [[NSMutableDictionary alloc] init];
    
    model[@"connection"] = [NSString stringWithFormat:@"%i", [[CometController sharedInstance] serverAvailable]];
    model[@"activeChat"] = [SenderCore sharedCore].activeChatsCoordinator.activeChatID ?: @"";
//  [model setObject:[[CometController sharedInstance] lastBatchID] forKey:@"lastBatchID"];
    NSString * conn = ([[ServerFacade sharedInstance] isWwan]) ? @"mob":@"wifi";
    model[@"con"] = conn;
    model[@"eventTime"] = [NSString stringWithFormat:@"%@", [NSDate date]];
    model[@"eventData"] = eventData;
    
    postData[@"chatId"] = [[CoreDataFacade sharedInstance] getOwner].senderChatId;
    postData[@"model"] = model;
    postData[@"class"] = @".ioslog.sender";
    
    LogEvent * event = (LogEvent *)[self getNewObjectWithName:@"LogEvent"];
    if (event) {
        [event addEvent:postData];
    }
    
    [self saveContext];
}

@end
