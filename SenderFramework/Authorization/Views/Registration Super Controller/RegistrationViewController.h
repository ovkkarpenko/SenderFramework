//
//  RegistrationViewController.h
//  SENDER
//
//  Created by Roman Serga on 29/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SenderFullAuthorizationPresenterProtocol;

@interface RegistrationViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) id<SenderFullAuthorizationPresenterProtocol> presenter;

@property (strong, nonatomic) UIButton * registerButton;

@property (nonatomic) BOOL registrationButtonEnabled;
@property (nonatomic) BOOL isActive;

- (void)setProgressHidden:(BOOL)hidden;

- (void)registerButtonPressed:(id)sender;

- (void)subscribeForNotifications;

- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardDidShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

- (void)hideKeyboard;
- (void)done;

//Method must be implemented by subclasses
- (void)showError:(NSString *)error completion:(void(^)())completion;
- (void)clearScreen;


@end
