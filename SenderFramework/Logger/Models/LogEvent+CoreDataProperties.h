//
//  LogEvent+CoreDataProperties.h
//  SENDER
//
//  Created by Eugene Gilko on 12/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LogEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface LogEvent (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *eventtime;
@property (nullable, nonatomic, retain) NSData *eventdata;

@end

NS_ASSUME_NONNULL_END
