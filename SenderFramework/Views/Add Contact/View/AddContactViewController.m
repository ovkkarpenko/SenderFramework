//
//  AddContactViewController.m
//  SENDER
//
//  Created by Roman Serga on 29/7/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "AddContactViewController.h"
#import "PBConsoleConstants.h"
#import "NSString(common_addition).h"
#import "ParamsFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface AddContactViewController ()

@property (nonatomic, weak) IBOutlet UITextField * userPhoneTextField;
@property (nonatomic, weak) IBOutlet UITextField * userNameTextField;
@property (nonatomic, weak) IBOutlet UIButton * addButton;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *separators;

@end

@implementation AddContactViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;

    self.userPhoneTextField.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    self.userNameTextField.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;

    self.userPhoneTextField.keyboardType = UIKeyboardTypePhonePad;

    self.tableView.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;

    if ([SenderCore sharedCore].stylePalette.lineColor)
    {
        for (UIView * separator in self.separators)
            separator.backgroundColor = [SenderCore sharedCore].stylePalette.lineColor;
    }

    self.addButton.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    self.addButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f];
    [self.addButton setTitleColor:[SenderCore sharedCore].stylePalette.actionButtonTitleColor
                         forState:UIControlStateNormal];
    [self.addButton setTitle:SenderFrameworkLocalizedString(@"add_contact_hing", nil) forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    self.userPhoneTextField.attributedPlaceholder = [[SenderCore sharedCore].stylePalette placeholderWithString:SenderFrameworkLocalizedString(@"new_contact_phone_ph_ios", nil)];
    self.userNameTextField.attributedPlaceholder = [[SenderCore sharedCore].stylePalette placeholderWithString:SenderFrameworkLocalizedString(@"contact_name_ph_ios", nil)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self customizeNavigationBarAnimated:animated];
}

- (void)customizeNavigationBarAnimated:(BOOL)animated
{
    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void)cancelButtonPressed
{
    [self.view endEditing:YES];
    [self.presenter cancelAddingContact];
}

-(void)doneButtonPressed
{
    [self.presenter addContactWithName:self.userNameTextField.text ?: @""
                                    phone:self.userPhoneTextField.text ?: @""];
}

#pragma mark - Text Field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.userPhoneTextField)
    {
        if (![textField.text length])
            textField.text = @"+";
    }
}

-(IBAction)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.userPhoneTextField)
        textField.text = [textField.text stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.contentView.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
}

- (void)showInvalidDataError
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"add_contact_wrong_number_title_ios", nil)
                                                                    message:SenderFrameworkLocalizedString(@"add_contact_wrong_number_desc_ios", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{

}


@end
