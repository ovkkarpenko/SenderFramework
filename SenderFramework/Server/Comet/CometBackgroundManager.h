//
//  CometBackgroundManager.h
//  SENDER
//
//  Created by Eugene Gilko on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CometBackgroundManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

+ (CometBackgroundManager *)sharedInstance;

- (void)runComet;

@end
