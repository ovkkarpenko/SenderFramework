//
//  LogerDBController.h
//  SENDER
//
//  Created by Eugene Gilko on 12/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreData/CoreData.h"

@interface LogerDBController : NSObject

@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;

+ (LogerDBController *)sharedCore;

- (void)saveContext;
- (void)deleteManagedObject:(NSManagedObject *)object;
- (NSArray *)findAllWithName:(NSString *)name
                    sortedBy:(NSString *)sortTerm
                   ascending:(BOOL)ascending
               withPredicate:(NSPredicate *)searchTerm;

- (void)addLogEvent:(NSDictionary *)eventData;

@end

