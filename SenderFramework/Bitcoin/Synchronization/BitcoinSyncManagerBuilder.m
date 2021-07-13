//
// Created by Roman Serga on 1/18/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "BitcoinSyncManagerBuilder.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation BitcoinSyncManagerBuilder
{
}

- (BitcoinSyncManager *)syncManagerWithRootViewController:(UIViewController *)rootViewController
                                                 delegate:(id<BitcoinSyncManagerDelegate>)delegate
{
    return [[BitcoinSyncManager alloc] initWithRootViewController:rootViewController andDelegate:delegate];
}

@end