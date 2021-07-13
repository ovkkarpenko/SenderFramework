//
//  MessagesGap.h
//  SENDER
//
//  Created by Roman Serga on 8/7/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dialog;

NS_ASSUME_NONNULL_BEGIN

@interface MessagesGap : NSManagedObject

- (BOOL)containsPacketID:(NSInteger)packetID;
- (BOOL)isIdenticalToGap:(MessagesGap *)gap;

@end

NS_ASSUME_NONNULL_END

#import "MessagesGap+CoreDataProperties.h"
