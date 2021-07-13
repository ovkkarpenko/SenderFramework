//
//  EnterPhoneViewController.m
//  SENDER
//
//  Created by Roman Serga on 19/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "EnterPhoneViewController.h"
#import "NSString(common_addition).h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "CountryListManager.h"
#import "NSArray+EqualContents.h"

#define EnterPrefixSegueID @"EnterPrefixEmbedded"

@interface EnterPhoneViewController ()

@property (strong, nonatomic) CALayer * phoneBottomBorder;

@property (nonatomic, weak) NSString * procID;

@property (nonatomic, weak) IBOutlet UILabel * titleLabel;
@property (nonatomic, weak) IBOutlet UIButton * userAgreementButton;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * containerViewCenter;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * tableViewHeight;
@property (nonatomic, weak) EnterPhonePrefixViewController * enterPrefixController;

@property (nonatomic, strong) NSArray <EnterPhoneCountryModel *> * countryList;

@property(nonatomic, strong) TermsConditionsModule * termsConditionsModule;

@end

@implementation EnterPhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self localize];
    [self customizeUI];
    [self loadCountryList];
}

- (void)customizeUI
{
    self.titleLabel.text = SenderFrameworkLocalizedString(@"enter_phone_title", nil);
    self.titleLabel.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    NSString * hint = SenderFrameworkLocalizedString(@"user_agreement_hint", nil);
    NSString * userAgreement = SenderFrameworkLocalizedString(@"user_agreement_name", nil);
    NSString * fullHintText = [NSString stringWithFormat:@"%@ %@", hint, userAgreement];
    
    NSMutableAttributedString * fullHintTextAttributed = [[NSMutableAttributedString alloc]initWithString:fullHintText];
    
    [fullHintTextAttributed addAttribute:NSForegroundColorAttributeName
                                   value:[[SenderCore sharedCore].stylePalette secondaryTextColor]
                                   range:[fullHintText rangeOfString:hint]];
    [fullHintTextAttributed addAttribute:NSForegroundColorAttributeName
                                   value:[[SenderCore sharedCore].stylePalette mainAccentColor]
                                   range:[fullHintText rangeOfString:userAgreement]];
    
    [self.userAgreementButton setAttributedTitle:fullHintTextAttributed forState:UIControlStateNormal];
    self.userAgreementButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)loadCountryList
{
    [CountryListManager loadCountryListWithCompletion:^(NSArray<EnterPhoneCountryModel *> * countryModels, NSError *error, BOOL isCachedModels)
    {
        if (countryModels && ![self.enterPrefixController.countries isContentEqualToArray:countryModels])
        {
            self.enterPrefixController.countries = countryModels;
            [self.enterPrefixController redrawTable];
        }
    }];
}

-(BOOL)canBecomeFirstResponder
{
    return !self.enterPrefixController.expanded;
}

- (EnterPhoneCountryModel *)defaultCountryModel
{
    return [[EnterPhoneCountryModel alloc]initWithName:SenderFrameworkLocalizedString(@"default_country_name", nil)
                                           countryCode:@""
                                               flagURL:nil];
}

- (void)hideKeyboard
{
    [self.enterPrefixController.phoneTextField resignFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self setProgressHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)localize
{
    if (((NSString *)_incommingMessge[@"model"][@"phone"]).length)
        self.enterPrefixController.phoneTextField.text = [NSString stringWithFormat:@"+%@", _incommingMessge[@"model"][@"phone"]];
}

- (BOOL)validate
{
    return [[[self.enterPrefixController getPhone] stringAsPhone]length] > 0;
}

- (void)sendPhoneToServer
{
    NSString *phone = [self.enterPrefixController getPhone];
    [self setProgressHidden:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.presenter sendPhone:phone
                   completion:^(MWSenderAuthorizationStepModel *_Nullable stepModel, NSError *_Nullable error)
                   {
                       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                       [self setProgressHidden:YES];
                       [self setRegisterButtonEnabled:YES];
                   }];
}

- (IBAction)showTermsAndConditions:(id)sender
{
    self.termsConditionsModule = [[TermsConditionsModule alloc] init];
    ModalInNavigationWireframe * wireframe = [[ModalInNavigationWireframe alloc] initWithRootView:self];
    [self.termsConditionsModule presentWithWireframe:wireframe forDelegate:self completion:nil];
}

- (void)registerButtonPressed:(id)sender
{
    if ([self validate])
    {
        [self sendPhoneToServer];
        [self setRegisterButtonEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setRegisterButtonEnabled:YES];
            [self setProgressHidden:YES];
        });
    }
    else {
        [self showError:SenderFrameworkLocalizedString(@"error_wrong_phone", nil) completion:nil];
    }
}

- (void)showError:(NSString *)error completion:(void (^)())completion
{
    self.titleLabel.text = error;

    [UIView animateWithDuration:0.3 animations:^{
        [self.titleLabel setTextColor:[[SenderCore sharedCore].stylePalette alertColor]];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetPhoneLabel];
        if (completion)
            completion();
    });
}

- (void)resetPhoneLabel
{
    [self clearScreen];
}

- (void)setRegisterButtonEnabled:(BOOL)enabled
{
    self.registerButton.enabled = enabled;
    self.registerButton.alpha = enabled ? 1.0f : 0.5f;
}

#pragma mark - Terms Conditions Delegate

- (void)termsConditionsModuleDidAccept
{
    [self.termsConditionsModule dismissWithCompletion:nil];
}

- (void)termsConditionsModuleDidDecline {}

#pragma mark - Keyboard Methods

- (void)keyboardWillShow:(NSNotification*)notification
{
    if ([self.enterPrefixController.phoneTextField isFirstResponder])
    {
        NSTimeInterval animationDuration = [[[notification userInfo]objectForKey:UIKeyboardAnimationDurationUserInfoKey]doubleValue];
        self.containerViewCenter.constant = IS_IPHONE_4_OR_LESS ? 190.0f : (IS_IPHONE_5 ? 145.0f : 110.0f);
        
        [UIView animateWithDuration:animationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval animationDuration = [[[notification userInfo]objectForKey:UIKeyboardAnimationDurationUserInfoKey]doubleValue];
    self.containerViewCenter.constant = 0.0f;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:EnterPrefixSegueID]) {
        self.enterPrefixController = segue.destinationViewController;
        self.enterPrefixController.delegate = self;
        [CountryListManager loadDefaultCountryWithCompletion:^(EnterPhoneCountryModel *countryModel, NSError *error, BOOL isCachedModel)
        {
            if (![self.enterPrefixController.chosenCountry isEqual:countryModel])
            {
                self.enterPrefixController.chosenCountry = countryModel;
                if (![self.enterPrefixController.countries count])
                    self.enterPrefixController.countries = @[self.enterPrefixController.chosenCountry];
                [self.enterPrefixController redrawTable];
            }
        }];
        [CATransaction setCompletionBlock:^{
            [self.enterPrefixController.phoneTextField becomeFirstResponder];
        }];
    }
}

#pragma mark - EnterPhonePrefix Delegate

-(BOOL)enterPhonePrefixViewController:(EnterPhonePrefixViewController *)controller shouldExpand:(BOOL)expanded
{
    return YES;
}

-(void)enterPhonePrefixViewController:(EnterPhonePrefixViewController *)controller willExpand:(BOOL)expanded
{
    if (expanded)
    {
        [CATransaction setCompletionBlock:^{
            self.tableViewHeight.constant = self.tableViewHeight.constant < 89.0f ? SCREEN_HEIGHT : 88.0f;
            [UIView animateWithDuration:0.3 animations:^{
                if ([self isFirstResponder])
                    [self resignFirstResponder];
                [self.view layoutIfNeeded];
            }];
        }];
    }
}

-(void)enterPhonePrefixViewController:(EnterPhonePrefixViewController *)controller didExpand:(BOOL)expanded
{
    if (!expanded)
    {
        [CATransaction setCompletionBlock:^{
            self.tableViewHeight.constant = self.tableViewHeight.constant < 89.0f ? SCREEN_HEIGHT : 88.0f;
            [UIView animateWithDuration:0.3 animations:^{
                if (self.enterPrefixController.phoneTextField)
                    [self.enterPrefixController.phoneTextField becomeFirstResponder];
                else
                    [self becomeFirstResponder];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
            }];
        }];
    }
}

- (void)clearScreen
{
    if (![self isViewLoaded])
        return;
    [self customizeUI];

    self.enterPrefixController.phoneTextField.text = @"";
}

@end
