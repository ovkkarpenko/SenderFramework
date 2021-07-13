//
//  ReachabilityOperator.h
//  SENDER
//
//  Created by Eugene on 4/6/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWReachability.h"

@interface ReachabilityOperator : NSObject
{
    MWReachability * checkReachable;
    UIView * connectingView;
    MWNetworkStatus internetStatus;
    BOOL isReachble;
}

+ (ReachabilityOperator *)sharedInstance;

- (MWNetworkStatus)getCurrentNetModel;
- (BOOL)getReachabilityStatus;

@end
