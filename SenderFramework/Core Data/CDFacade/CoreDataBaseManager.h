//
//  CodeDataBaseManager.h
//  SENDER
//
//  Created by Eugene Gilko on 10/8/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreData/CoreData.h"

@interface CoreDataBaseManager : NSObject

+ (CoreDataBaseManager *)sharedManager;

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request;
- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName;
- (NSFetchRequest *)getRequestForObjectWithName:(NSString *)name;
- (NSManagedObject *)getNewObjectWithName:(NSString *)entityName inContex:(NSManagedObjectContext *)context;
- (void)deleteObject:(NSManagedObject *)object;
- (void)saveContext;
- (BOOL)deleteAll;

@end
