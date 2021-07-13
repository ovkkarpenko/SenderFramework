//
//  RegistrationViewController.m
//  SENDER
//
//  Created by Roman Serga on 29/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "RegistrationViewController.h"
#import "ProgressView.h"
#import "PBConsoleConstants.h"
#import "SenderNotifications.h"
#import <SenderFramework/SenderFramework-Swift.h>

#define registerButtonHeight 56.0f

@interface RegistrationViewController ()

@property (nonatomic, strong) UIView * registerButtonBackground;
@property (nonatomic, strong) ProgressView * progressView;

@end

@implementation RegistrationViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

-(UIView *)inputAccessoryView
{
    return self.registerButtonBackground;
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.progressView = [[ProgressView alloc]init];

    CGFloat backgroundHeight = registerButtonHeight + 8.0f + self.progressView.frame.size.height;
    CGRect backgroundFrame = CGRectMake(0.0,
                                        self.view.frame.size.height - backgroundHeight,
                                        self.view.frame.size.width,
                                        backgroundHeight);
    
    self.registerButtonBackground = [[UIView alloc]initWithFrame:backgroundFrame];
    self.registerButtonBackground.backgroundColor = [UIColor clearColor];
    
    self.registerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.registerButton.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    [self.registerButton setTitleColor:[SenderCore sharedCore].stylePalette.actionButtonTitleColor
                              forState:UIControlStateNormal];
    [self.registerButton addTarget:self
                            action:@selector(registerButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.registerButton setTitle:[SenderFrameworkLocalizedString(@"register_ios", nil) uppercaseString]
                         forState:UIControlStateNormal];

    self.progressView.frame = CGRectMake((self.registerButtonBackground.frame.size.width - self.progressView.frame.size.width)/2,
                                         0.0f,
                                         self.progressView.frame.size.width,
                                         self.progressView.frame.size.height);

    self.registerButton.frame = CGRectMake(0.0,
                                           self.registerButtonBackground.frame.size.height - registerButtonHeight,
                                           self.view.frame.size.width,
                                           registerButtonHeight);
    
    [self.registerButtonBackground addSubview:self.progressView];
    [self.registerButtonBackground addSubview:self.registerButton];

    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    
    [self setProgressHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    self.registerButton.enabled = YES;
    [self subscribeForNotifications];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeFirstResponder)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)subscribeForNotifications
{
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardDidShow:)
                                                name:UIKeyboardDidShowNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];
}

- (void)setRegistrationButtonEnabled:(BOOL)registrationButtonEnabled
{
    _registrationButtonEnabled = registrationButtonEnabled;
    self.registerButton.userInteractionEnabled = registrationButtonEnabled;
    self.registerButton.alpha = registrationButtonEnabled ? 1.0f : 0.3f;
}

- (void)setIsActive:(BOOL)isActive
{
    _isActive = isActive;
    self.registrationButtonEnabled = isActive;
}

-(void)registerButtonPressed:(id)sender {}


- (void)setProgressHidden:(BOOL)hidden
{
    self.progressView.hidden = hidden;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)keyboardWillShow:(NSNotification *)notification {}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)keyboardDidShow:(NSNotification*)notification {}

- (void)textFieldDidBeginEditing:(UITextField *)textField {}

- (void)textFieldDidEndEditing:(UITextField *)textField {}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self hideKeyboard];
}

#pragma mark - Done Button

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)done
{
    [self.view endEditing:YES];
}

- (void)showError:(NSString *)error completion:(void(^)())completion
{
    completion();
}

- (void)clearScreen
{

}


@end
