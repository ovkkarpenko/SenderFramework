//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "WaitForIVRViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface WaitForIVRViewController()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) IBOutlet UILabel *confirmIVRDescription;
@property (strong, nonatomic) IBOutlet UIImageView *confirmIVRIconView;

@property (nonatomic, strong) NSTimer * cancelIVRButtonTimer;

@property (nonatomic, strong) NSString * phoneNumber;
@end

@implementation WaitForIVRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.confirmIVRIconView.image = [[SenderCore sharedCore].stylePalette.welcomeViewControllerLogo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.confirmIVRIconView.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    self.confirmIVRDescription.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];

    if ([self.incomingMessage[@"phone"] isKindOfClass: [NSString class]])
        self.phoneNumber = self.incomingMessage[@"phone"];

    [self localize];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self setProgressHidden:YES];
    [self.cancelIVRButtonTimer invalidate];
    self.presenter.eventHandler = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isActive = YES;
    [self customizeViewForIVR:self.incomingMessage];
    self.presenter.eventHandler = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)customizeViewForIVR:(NSDictionary *)response
{
    self.isActive = NO;

    NSTimeInterval waitInterval = [response[@"wait"] intValue];
    if (waitInterval > 0)
    {
        self.cancelIVRButtonTimer = [NSTimer scheduledTimerWithTimeInterval:waitInterval
                                                                     target:self
                                                                   selector:@selector(enableCancelIVR)
                                                                   userInfo:nil repeats:NO];
    }
    else
    {
        self.isActive = YES;
    }

}

- (void)showError:(NSString *)error completion:(void (^)())completion
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion)
            completion();
    });
}

- (void)cancelWaitForIVR:(id)sender
{
    self.registerButton.enabled = NO;
    [self.registerButton performSelector:@selector(setEnabled:) withObject:@YES afterDelay:5.0f];
    [self.presenter cancelWaitingForIVRWithCompletion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {

    }];
}

-(void)localize
{
    self.confirmIVRDescription.text = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"wait_ivr_ios", nil), self.phoneNumber];
    [self.registerButton setTitle:[SenderFrameworkLocalizedString(@"cancel", nil) uppercaseString] forState:UIControlStateNormal];
}

-(void)registerButtonPressed:(id)sender
{
    [self cancelWaitForIVR:sender];
}

- (void)enableCancelIVR
{
    self.isActive = YES;
}

@end
