//
//  EnterNameViewController.m
//  SENDER
//
//  Created by Roman Serga on 20/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "EnterNameViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface EnterNameViewController ()

@property (weak, nonatomic) IBOutlet UILabel *enterNameTitle;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) CALayer * nameBottomBorder;
@property (strong, nonatomic) UITapGestureRecognizer *recognizer;

@end

@implementation EnterNameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nameTextField.tintColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
    self.nameBottomBorder = [CALayer layer];
    self.nameBottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette lineColor].CGColor;
    [self.nameTextField.layer addSublayer:self.nameBottomBorder];

    [self resetNameLabel];
    
    [self localize];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.nameBottomBorder.frame = CGRectMake(0.0f,
                                             self.nameTextField.frame.size.height - 1.0f,
                                             self.nameTextField.frame.size.width,
                                             1.0f);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /*
     * Calling layoutIfNeeded because of some reason viewDidLayoutSubviews not called following
     * resizing nameTextField after loading view controller from storyboard
     */
    [self.view layoutIfNeeded];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [self.nameTextField becomeFirstResponder];
    self.isActive = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self done];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [super viewWillDisappear:animated];
}

-(void)localize
{
    self.enterNameTitle.text = SenderFrameworkLocalizedString(@"enter_name_ios", nil);
}

-(BOOL)validate
{
    return [[self.nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] length] > 0;
}

- (void)registerButtonPressed:(id)sender
{
    if ([self validate])
    {
        self.isActive = NO;

        [self.presenter sendName:self.nameTextField.text
                      completion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {
            if (error)
                self.isActive = YES;
        }];
    }
    else
    {
        [self showError:SenderFrameworkLocalizedString(@"enter_name_message_ios", nil) completion:nil];
    }
}

- (void)showError:(NSString *)error completion:(void (^)())completion
{
    [self setProgressHidden:YES];
    self.enterNameTitle.text = error;
    [self.enterNameTitle setTextColor:[[SenderCore sharedCore].stylePalette alertColor]];
    self.nameBottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor].CGColor;
    [self.nameTextField setTextColor:[[SenderCore sharedCore].stylePalette alertColor]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetNameLabel];
        if (completion)
            completion();
    });
}

- (void)resetNameLabel
{
    [self.enterNameTitle setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];
    self.enterNameTitle.text = SenderFrameworkLocalizedString(@"enter_name_ios", nil);
    self.nameBottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette lineColor].CGColor;
    [self.nameTextField setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];
}

#pragma mark - TextField Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
    
#pragma mark - Keyboard Methods

- (void)keyboardWillShow:(NSNotification*)notification
{
    if ([self.nameTextField isFirstResponder])
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.view.transform = CGAffineTransformMakeTranslation(0, -120);
        }];
    }
}

- (void)clearScreen
{
    if (![self isViewLoaded])
        return;

    self.nameTextField.text = @"";
    [self resetNameLabel];
}

@end
