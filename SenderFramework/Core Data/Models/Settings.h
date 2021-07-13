//
//  Settings.h
//  SENDER
//
//  Created by Roman Serga on 11/2/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Owner;

@interface Settings : NSManagedObject

@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * theme;
@property (nonatomic, retain) NSNumber * sendRead;
@property (nonatomic, retain) NSNumber * adultContent;
@property (nonatomic, retain) NSNumber * messageFilter;
@property (nonatomic, retain) NSNumber * sounds;
@property (nonatomic, retain) NSNumber * location;
@property (nonatomic, retain) NSNumber * notificationsSound;
@property (nonatomic, retain) NSNumber * notificationsVibration;
@property (nonatomic, retain) NSNumber * notificationsFlash;
@property (nonatomic, retain) NSNumber * personalBackgrounds;
@property (nonatomic, retain) Owner *owner;

@end
