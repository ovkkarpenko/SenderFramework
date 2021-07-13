//
//  UIAlertView+CompletionHandler.h
//  SENDER
//
//  Created by Roman Serga on 24/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIAlertView (CompletionHandler)

- (void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;
- (void)showWithDismissCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
