//
// Created by Roman Serga on 1/18/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BitcoinSyncManager;
@protocol BitcoinSyncManagerDelegate;

@interface BitcoinSyncManagerBuilder : NSObject

- (nonnull BitcoinSyncManager *)syncManagerWithRootViewController:(UIViewController *_Nonnull)rootViewController
                                                 delegate:(id <BitcoinSyncManagerDelegate> _Nullable)delegate;

@end
