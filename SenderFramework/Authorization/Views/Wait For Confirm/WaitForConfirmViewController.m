//
//  WaitForConfirmViewController.m
//  SENDER
//
//  Created by Roman Serga on 13/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "WaitForConfirmViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface WaitForConfirmViewController ()

@property (nonatomic, weak) IBOutlet UIImageView * logoImageView;
@property (nonatomic, weak) IBOutlet UILabel * titleLabel;

@property (nonatomic, strong) NSString * phoneNumber;
@end

@implementation WaitForConfirmViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self resetTitleLabel];

    self.logoImageView.image = [[SenderCore sharedCore].stylePalette.welcomeViewControllerLogo imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.logoImageView.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    [self.registerButton setTitle:[SenderFrameworkLocalizedString(@"cancel", nil) uppercaseString] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.presenter.eventHandler = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.presenter.eventHandler = nil;
}

-(void)resetTitleLabel
{
    [self clearScreen];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)registerButtonPressed:(id)sender
{
    self.registerButton.enabled = NO;
    [self.registerButton performSelector:@selector(setEnabled:) withObject:@YES afterDelay:5.0f];
    [self.presenter cancelWaitingForConfirmWithCompletion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {
    }];
}

-(void)showError:(NSString *)error completion:(void (^)())completion
{
    [self setProgressHidden:YES];
    
    self.titleLabel.text = error;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.titleLabel setTextColor:[[SenderCore sharedCore].stylePalette alertColor]];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetTitleLabel];
        if (completion)
            completion();
    });
}

- (void)clearScreen
{
    if (![self isViewLoaded])
        return;

    self.titleLabel.text = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"confirm_auth_detail_ios", nil),
                                                      (self.deviceName.length) ? self.deviceName : @""];
    self.titleLabel.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
}

@end
