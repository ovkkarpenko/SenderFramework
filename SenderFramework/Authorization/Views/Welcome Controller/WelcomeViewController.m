//
//  WelcomeViewController.m
//  SENDER
//
//  Created by Eugene on 12/17/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "BitcoinWallet.h"
#import "CoreDataFacade.h"
#import "WelcomeViewController.h"
#import "ServerFacade.h"
#import "CoreDataFacade.h"
#import "PBConsoleConstants.h"
#import "ProgressView.h"
#import "SecGenerator.h"
#import "CometController.h"
#import "UIAlertView+CompletionHandler.h"

#import "EnterPhoneViewController.h"
#import "WaitForConfirmViewController.h"
#import "EnterOTPViewController.h"
#import "EnterNameViewController.h"
#import "AddPhotoViewController.h"
#import "LogerDBController.h"
#import "AddressBook.h"
#import "SenderFrameworkGlobals.h"
#import <SenderFramework/SenderFramework-Swift.h>

#import "Owner.h"
#import "AddressBook.h"
#import "BitcoinSyncManagerBuilder.h"
#import "ParamsFacade.h"
#import "UIView+MWSubviews.h"

#import "SenderCore.h"

@interface WelcomeViewController ()
{
    ProgressView * progressView;
    UIStoryboard * registrationStoryboard;

}

@end


@implementation WelcomeViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    registrationStoryboard = [UIStoryboard storyboardWithName:@"Registration" bundle:NSBundle.senderFrameworkResourcesBundle];

    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];

    [self addBackgroundImage:[SenderCore sharedCore].stylePalette.welcomeViewControllerBackgroundImage];
    [self addLogoImage:[SenderCore sharedCore].stylePalette.welcomeViewControllerLogo];
    
    progressView = [[ProgressView alloc] initWithText:SenderFrameworkLocalizedString(@"launching_app_ios", nil)];
    [self addProgressView:progressView];
    
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:animated];
}

- (void)addBackgroundImage:(UIImage *)backgroundImage
{
    UIImageView * backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backgroundImageView];
    [self.view mw_pinSubview:backgroundImageView];
}

- (void)addLogoImage:(UIImage *)logoImage
{
    UIImageView * logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.center = self.view.center;
    [self.view addSubview:logoImageView];
}

- (void)addProgressView:(UIView *)progress
{
    progress.tintColor = [SenderCore sharedCore].stylePalette.welcomeViewControllerProgressColor;
    
    [self.view addSubview:progress];
    progress.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint * xCenter = [NSLayoutConstraint constraintWithItem:progress
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0f
                                                                 constant:0.0f];
    
    NSLayoutConstraint * bottomSpace = [NSLayoutConstraint constraintWithItem:progress
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0f
                                                                     constant:-20.0f];
    
    
    NSLayoutConstraint * leftSpace = [NSLayoutConstraint constraintWithItem:progress
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1.0f
                                                                   constant:20.0f];
    
    NSLayoutConstraint * rightSpace = [NSLayoutConstraint constraintWithItem:progress
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationLessThanOrEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0f
                                                                    constant:-20.0f];
    
    
    [self.view addConstraint:bottomSpace];
    [self.view addConstraint:xCenter];
    [self.view addConstraint:leftSpace];
    [self.view addConstraint:rightSpace];
}

#pragma mark  SyncContacts

- (void)setProgressText:(NSNotification *)notification
{
    [progressView setText:(NSString *)[notification object]];
}

@end
