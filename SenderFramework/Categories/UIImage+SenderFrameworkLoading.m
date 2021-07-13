//
// Created by Roman Serga on 25/10/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "UIImage+SenderFrameworkLoading.h"
#import "NSBundle+SenderFrameworkLoading.h"

@implementation UIImage (SenderFrameworkLoading)

+ (UIImage *)imageFromSenderFrameworkNamed:(NSString *)name
{
    NSBundle * frameworkBundle = NSBundle.senderFrameworkResourcesBundle;

    if (frameworkBundle)
        return [UIImage imageNamed:name inBundle:frameworkBundle compatibleWithTraitCollection:nil];
    else
        return nil;
}

@end
