//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "UIStoryboard+SenderFrameworkLoading.h"

@implementation UIStoryboard (SenderFrameworkLoading)

+ (UIStoryboard *)storyboardFromSenderFrameworkWithName:(NSString *)name
{
    NSBundle * senderFrameworkResourcesBundle = NSBundle.senderFrameworkResourcesBundle;
    if (senderFrameworkResourcesBundle == nil) {
        [NSException raise:@"Cannot load SenderFrameworkResources bundle."
                    format:@"Cannot load SenderFrameworkResources bundle."];
        return nil;
    }

    return [UIStoryboard storyboardWithName:name bundle:senderFrameworkResourcesBundle];
}

@end