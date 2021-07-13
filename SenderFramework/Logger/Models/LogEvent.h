//
//  LogEvent.h
//  SENDER
//
//  Created by Eugene Gilko on 12/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogEvent : NSManagedObject

- (void)addEvent:(NSDictionary *)newEvent;

@end

NS_ASSUME_NONNULL_END

#import "LogEvent+CoreDataProperties.h"
