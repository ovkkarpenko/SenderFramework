//
//  SenderConstants.h
//  SENDER
//
//  Created by Roman Serga on 25/5/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AppDelegate;
@class SenderCore;

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define SENDER_FRAMEWORK_BUNDLE [NSBundle bundleForClass:[SenderCore class]]
#define SENDER_SHARED_CORE  [SenderCore sharedCore]

#ifdef DEBUG
#	define  NLog(fmt, ...) NSLog((@"%s " fmt), __FUNCTION__, ##__VA_ARGS__);
#	define  LLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#	define  NLog(...)
#	define  LLog(...)
#endif

#ifndef dispatch_main_async_safe
    #define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
        if ([NSThread isMainThread]) {\
            block();\
        } else {\
            dispatch_sync(dispatch_get_main_queue(), block);\
        }
#endif