//
//  EnterOTPViewController.m
//  SENDER
//
//  Created by Roman Serga on 20/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "EnterOTPViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface EnterOTPViewController ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (weak, nonatomic) IBOutlet UIView *otpView;
@property (weak, nonatomic) IBOutlet UITextField *firstTF;
@property (weak, nonatomic) IBOutlet UITextField *secondTF;
@property (weak, nonatomic) IBOutlet UITextField *thirdTF;
@property (weak, nonatomic) IBOutlet UITextField *fourthTF;

@property (weak, nonatomic) IBOutlet UIButton *notReceivedButton;
@property (weak, nonatomic) IBOutlet UILabel *enterCodeTitle;

@property (strong, nonatomic) NSArray * otpFieldsBottomBorders;

@property (nonatomic, strong) NSTimer * showIVRButtonTimer;

@property (nonatomic) BOOL isIVRScreen;

@property (nonatomic, strong) NSString * phoneNumber;
@end

@implementation EnterOTPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    self.otpFieldsBottomBorders = [NSArray array];
    
    for (UITextField * digitField in @[self.firstTF, self.secondTF, self.thirdTF, self.fourthTF])
    {
        digitField.tintColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
        digitField.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
        CALayer * bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, digitField.frame.size.height - 1.0f, digitField.frame.size.width, 1.0f);
        bottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette lineColor].CGColor;
        [digitField.layer addSublayer:bottomBorder];
        self.otpFieldsBottomBorders = [self.otpFieldsBottomBorders arrayByAddingObject:bottomBorder];
    }
    
    [self resetPhoneLabel];
    [self localize];

    if ([self.incomingMessage[@"phone"] isKindOfClass: [NSString class]])
        self.phoneNumber = self.incomingMessage[@"phone"];

    NSTimeInterval waitInterval = [self.incomingMessage[@"wait"] intValue];
    if (waitInterval > 0)
    {
        self.notReceivedButton.hidden = YES;
        self.showIVRButtonTimer = [NSTimer scheduledTimerWithTimeInterval:waitInterval
                                                                   target:self
                                                                 selector:@selector(showIVRButton)
                                                                 userInfo:nil
                                                                  repeats:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self setProgressHidden:YES];
    [self.showIVRButtonTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self done];
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.isActive = YES;
    [self resetPhoneLabel];
    [self.firstTF performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showError:(NSString *)error completion:(void (^)())completion
{
    for (CALayer * bottomBorder in self.otpFieldsBottomBorders)
    {
        bottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette alertColor].CGColor;
    }
    
    for (UITextField * digitField in @[self.firstTF, self.secondTF, self.thirdTF, self.fourthTF])
    {
        [digitField setTextColor:[[SenderCore sharedCore].stylePalette alertColor]];
    }
    self.enterCodeTitle.text = error;
    [self.enterCodeTitle setTextColor:[SenderCore sharedCore].stylePalette.alertColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resetPhoneLabel];
        [self.firstTF becomeFirstResponder];
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

- (void)resetPhoneLabel
{
    [self clearScreen];
}

-(void)localize
{
    [self.notReceivedButton setAttributedTitle:[[NSAttributedString alloc]initWithString: SenderFrameworkLocalizedString(@"not_received_otp_ios", nil) attributes:
                                                @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                  NSForegroundColorAttributeName : [[SenderCore sharedCore].stylePalette secondaryTextColor]}] forState:UIControlStateNormal];
    self.enterCodeTitle.text = SenderFrameworkLocalizedString(@"enter_otp_ios", nil);
    [self.registerButton setTitle:[SenderFrameworkLocalizedString(@"register_ios", nil) uppercaseString] forState:UIControlStateNormal];
}

-(BOOL)validate
{
    NSString *otp = [self getFullOTPText];
    return [otp length] != 0;
}

- (BOOL)checkIsDigit:(NSString *)text
{
    char ch = [text characterAtIndex:0];
    return isdigit(ch);
}

- (NSString *)getFullOTPText
{
    NSString * fullCode = [NSString stringWithFormat:@"%@%@%@%@", self.firstTF.text, self.secondTF.text, self.thirdTF.text, self.fourthTF.text];
    NSString *toReturn = [fullCode stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];
    if ([toReturn length] < 4)
        return [NSString string];
    else
        return toReturn;
}

-(void)registerButtonPressed:(id)sender
{
    if (self.isIVRScreen)
    {
        [self cancelWaitForIVR:sender];
    }
    else
    {
        if ([self validate])
        {
            self.isActive = NO;
            
            [self setProgressHidden:NO];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [self.presenter sendOTP:[self getFullOTPText]
                         completion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {
                             [self setProgressHidden:YES];
                             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
              }];
        }
        else
        {
            [self showError:SenderFrameworkLocalizedString(@"enter_otp_message_ios", nil) completion:nil];
        }
    }
}

- (void)showIVRButton
{
    self.notReceivedButton.hidden = NO;
}

- (IBAction)requestIVR:(id)sender
{
    [self.presenter requestIVRConfirmationWithCompletion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {
        [self setProgressHidden:NO];
    }];
}

#pragma mark - TextField Methods

- (IBAction)textFieldDidChange:(UITextField *)textField
{
    NSString * text = textField.text;
    
    if (text.length < 2)
    {
        textField.text = @"\u200B";
        
        if (textField == self.secondTF) {
            self.firstTF.text = @"\u200B";
            [self.firstTF performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
        }
        else if (textField == self.thirdTF) {
            self.secondTF.text = @"\u200B";
            [self.secondTF performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
        }
        else if (textField == self.fourthTF) {
            self.thirdTF.text = @"\u200B";
            [self.thirdTF performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.001];
        }
    }
    else if (text.length == 2)
    {
        if (![self checkIsDigit:[text substringFromIndex:1]]) {
            textField.text = [text substringToIndex:text.length - 1];
            return;
        }
        if (textField == self.firstTF) {
            [self.secondTF becomeFirstResponder];
        }
        else if (textField == self.secondTF) {
            [self.thirdTF becomeFirstResponder];
        }
        else if (textField == self.thirdTF) {
            [self.fourthTF becomeFirstResponder];
        }
        else if (textField == self.fourthTF) {
            [self.fourthTF resignFirstResponder];
        }
    }
    else if (text.length == 3) {
        NSString *new = [text substringWithRange:(NSRange){2, 1}];
        textField.text = [text substringToIndex:text.length - 1];
        
        if (textField == self.firstTF && self.secondTF.text.length < 2) {
            self.secondTF.text = [self.secondTF.text stringByAppendingString:new];
            [self.secondTF becomeFirstResponder];
        }
        else if (textField == self.secondTF && self.thirdTF.text.length < 2) {
            self.thirdTF.text = [self.thirdTF.text stringByAppendingString:new];
            [self.thirdTF becomeFirstResponder];
        }
        else if (textField == self.thirdTF && self.fourthTF.text.length < 2) {
            self.fourthTF.text = [self.fourthTF.text stringByAppendingString:new];
            [self.fourthTF becomeFirstResponder];
        }
    }
    else
    {
        textField.text = @"\u200B";
    }
    
    NSString *otp = [self getFullOTPText];
    if (otp.length == 4) {
        [self registerButtonPressed:nil];
    }
}

#pragma mark - Keyboard Methods

- (void)keyboardWillShow:(NSNotification*)notification
{
    for (UITextField * textField in @[self.firstTF, self.secondTF, self.thirdTF, self.fourthTF]) {
        if ([textField isFirstResponder])
        {
            [UIView animateWithDuration:0.3f animations:^{
                self.view.transform = CGAffineTransformMakeTranslation(0, -110);
            }];
            break;
        }
    }
}

- (void)clearScreen
{
    if (![self isViewLoaded])
        return;

    for (CALayer * bottomBorder in self.otpFieldsBottomBorders)
    {
        bottomBorder.backgroundColor = [[SenderCore sharedCore].stylePalette lineColor].CGColor;
    }

    for (UITextField * digitField in @[self.firstTF, self.secondTF, self.thirdTF, self.fourthTF])
    {
        digitField.text = @"\u200B";
        [digitField setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];
    }

    self.enterCodeTitle.text = SenderFrameworkLocalizedString(@"enter_otp_ios", nil);
    [self.enterCodeTitle setTextColor:[[SenderCore sharedCore].stylePalette secondaryTextColor]];

    self.isActive = YES;
}

@end
