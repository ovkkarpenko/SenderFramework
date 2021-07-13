//
//  PBConsoleManager.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBConsoleManager.h"
#import "ParamsFacade.h"
#import "MainContainerModel.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation PBConsoleManager

+ (PBConsoleView * _Nonnull)buildConsoleViewFromDate:(Message *)model forViewController:(UIViewController *)viewController
{
    __strong MainContainerModel * cellModel = [[MainContainerModel alloc] initWithMessageData:model];
    return [[PBConsoleView alloc] initWithCellModel:cellModel
                                            message:model
                                            forRect:[self screenBounds]
                                 rootViewController:viewController];
}

+ (PBConsoleView * _Nonnull)buildConsoleViewFromDate:(Message *)model
                                            maxWidth:(CGFloat)maxWidth
                                            delegate:(id<PBConsoleViewDelegate>)delegate
{
    __strong MainContainerModel * cellModel = [[MainContainerModel alloc] initWithMessageData:model];
    return [[PBConsoleView alloc] initWithCellModel:cellModel
                                            message:model
                                            forRect:CGRectMake(0.0, 0.0, maxWidth, FLT_MAX)
                                           delegate:delegate];
}

+ (CGRect)screenBounds
{
    return [[UIScreen mainScreen] bounds];
}

@end
