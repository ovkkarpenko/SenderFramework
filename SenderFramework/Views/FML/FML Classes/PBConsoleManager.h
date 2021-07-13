//
//  PBConsoleManager.h
//  
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBConsoleView.h"
#import "Message.h"
#import "PBSubviewFacade.h"

@interface PBConsoleManager : NSObject

+ (PBConsoleView * _Nonnull)buildConsoleViewFromDate:(Message *)model
                                   forViewController:(UIViewController *)viewController;

+ (PBConsoleView * _Nonnull)buildConsoleViewFromDate:(Message *)model
                                            maxWidth:(CGFloat)maxWidth
                                            delegate:(id<PBConsoleViewDelegate>)delegate;

@end
