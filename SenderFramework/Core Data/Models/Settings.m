//
//  Settings.m
//  SENDER
//
//  Created by Roman Serga on 11/2/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "Settings.h"
#import "Owner.h"


@implementation Settings

@dynamic language;
@dynamic sendRead;
@dynamic adultContent;
@dynamic messageFilter;
@dynamic sounds;
@dynamic notificationsSound;
@dynamic notificationsFlash;
@dynamic notificationsVibration;
@dynamic personalBackgrounds;
@dynamic owner;
@dynamic location;
@dynamic theme;

-(void)setTheme:(NSString *)theme
{
    [self willChangeValueForKey:@"theme"];
    [self setPrimitiveValue:theme forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] setObject:theme forKey:@"StyleApp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self didChangeValueForKey:@"theme"];
}

@end
