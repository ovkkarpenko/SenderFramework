//
// Created by Roman Serga on 26/10/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "NSBundle+SenderFrameworkLoading.h"

@implementation NSBundle (SenderFrameworkLoading)

+ (NSBundle *)senderFrameworkResourcesBundle
{
    NSString * path = [SENDER_FRAMEWORK_BUNDLE pathForResource:@"SenderFrameworkResources" ofType:@"bundle"];
    if (path)
    {
        NSBundle * senderBundle = [NSBundle bundleWithPath:path];
        if (senderBundle)
        {
            return senderBundle;
        }
        else
        {
            LLog("Cannot load SenderFrameworkResources bundle.");
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

@end
