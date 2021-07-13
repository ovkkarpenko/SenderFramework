//
//  ReachabilityOperator.m
//  SENDER
//
//  Created by Eugene on 4/6/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import "ReachabilityOperator.h"


static ReachabilityOperator * operator;

@implementation ReachabilityOperator

+ (ReachabilityOperator *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        operator = [[ReachabilityOperator alloc] init];
    });
    
    return operator;
}

- (id)init
{
    [self setupReachability];
    return self;
}

- (void)setupReachability
{
    NSString * remoteHostName = @"senderapi.com";
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkNetworkStatus:)
                                                 name:kMWReachabilityChangedNotification object:nil];
    
    checkReachable = [MWReachability reachabilityWithHostName:remoteHostName];
    [checkReachable startNotifier];
}

- (void)checkNetworkStatus:(NSNotification *)notice
{
    internetStatus = [checkReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case MWNetworkStatusNotReachable:
        {
            isReachble = NO;
            [self addConnectingViewToWindow:SENDER_SHARED_CORE.window];
            break;
        }
        case MWNetworkStatusReachableViaWiFi:
        {
            isReachble = YES;
            [self removeConnectingView];
            break;
        }
        case MWNetworkStatusReachableViaWWAN:
        {
            isReachble = YES;
            [self removeConnectingView];
            break;
        }
            default:
            break;
    }
}

- (MWNetworkStatus)getCurrentNetModel
{
    return internetStatus;
}

- (BOOL)getReachabilityStatus
{
    return isReachble;
}

#pragma mark Connection View

- (void)addConnectingViewToWindow:(UIWindow *)window
{
    if (!connectingView)
    {
        CGFloat width = 200.0f;
        CGFloat height = 30.0f;
        connectingView = [[UIView alloc]initWithFrame:CGRectMake((window.frame.size.width - width) / 2, 25.0f, width, height)];
        connectingView.backgroundColor = [[UIColor redColor]colorWithAlphaComponent:0.2f];
        connectingView.layer.cornerRadius = 10.0f;
        connectingView.userInteractionEnabled = NO;

        UILabel * connectingLabel = [[UILabel alloc]initWithFrame:CGRectMake(15.0f, 0.0f, 120.0f, height)];
        connectingLabel.userInteractionEnabled = NO;
        connectingLabel.textColor = [[UIColor redColor]colorWithAlphaComponent:0.5f];
        connectingLabel.text = SenderFrameworkLocalizedString(@"connecting_ios", nil);
        
        UIActivityIndicatorView * spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(width - height - 20.0f, 0.0f, height, height)];
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        spinner.color = [[UIColor redColor]colorWithAlphaComponent:0.5f];
        [spinner startAnimating];
        
        [connectingView addSubview:connectingLabel];
        [connectingLabel addSubview:spinner];
        
        [window addSubview: connectingView];
    }
}

- (void)removeConnectingView
{
    if (connectingView)
    {
        [connectingView removeFromSuperview];
        connectingView = nil;
    }
}

@end
