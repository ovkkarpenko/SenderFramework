//
//  SettingsViewController.m
//  SENDER
//
//  Created by Eugene on 11/4/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIImage+Resize.h"
#import "ServerFacade.h"
#import "SenderNotifications.h"
#import "ParamsFacade.h"
#import "CoreDataFacade.h"
#import "PBConsoleConstants.h"
#import "UIImageView (UITextFieldBackground).h"
#import "Settings.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "DialogSetting.h"
#import "CometController.h"
#import "UIAlertView+CompletionHandler.h"
#import "BitcoinSyncManagerBuilder.h"
#import "ChatListChatViewModel.h"
#import "ChatPickerViewController.h"

@interface SettingsViewController ()
{
    NSInteger blackListCount;
    UserInfoEditorModule * userInfoEditorModule;
    SubviewWireframe * userInfoEditorWireframe;
}

@end

@implementation SettingsViewController

#pragma mark - View Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    syncManager = [[SenderCore sharedCore].bitcoinSyncManagerBuilder syncManagerWithRootViewController:self
                                                                                              delegate:self];
    syncManager.dataSource = self;
    
    for (UILabel * label in @[lbDisableDeviceTitle, lbClearHistoryTitle, lbBitcoinWallet, lbMyDevicesTitle])
        label.textColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    self.title = SenderFrameworkLocalizedString(@"settings", nil);
    [self customizeNavigationBar];
    [self localize];
    [self initSwitches];
    [self.presenter viewWasLoaded];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    self.tableView.backgroundColor = [SenderCore sharedCore].stylePalette.commonTableViewBackgroundColor;

    if ([SenderCore sharedCore].stylePalette.lineColor)
        self.tableView.separatorColor = [SenderCore sharedCore].stylePalette.lineColor;

    userInfoEditorWireframe = [[SubviewWireframe alloc] initWithParentViewController:self
                                                                           superView:userInfoCell.contentView];
    userInfoEditorModule = [[UserInfoEditorModule alloc] init];

    [userInfoEditorModule presentWithWireframe:userInfoEditorWireframe
                                   forDelegate:nil
                                    completion:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navigationController]setNavigationBarHidden:NO animated:YES];

//    Workaround for quick swipe-to-back to ChatListViewController and back to SettingsViewController
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self navigationController]setNavigationBarHidden:NO animated:animated];
    });
}

-(void)initSwitches
{
    swReadStatus = [[UISwitch alloc]init];
    swLocation = [[UISwitch alloc]init];
    swSounds = [[UISwitch alloc]init];
    swNotificationsSound = [[UISwitch alloc]init];
    swNotificationsVibration = [[UISwitch alloc]init];
    swNotificationsFlash = [[UISwitch alloc]init];

    for (UISwitch * uiSwitch in @[swReadStatus, swLocation, swSounds, swNotificationsSound, swNotificationsVibration, swNotificationsFlash])
    {
        [uiSwitch setOnTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
        [uiSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString * title;
    switch (section) {
        case 0:
            title = SenderFrameworkLocalizedString(@"general_ios", nil);
            break;
        case 1:
            title = SenderFrameworkLocalizedString(@"sound_settings_title_ios", nil);
            break;
        case 2:
            title = SenderFrameworkLocalizedString(@"reset_settings_title_ios", nil);
            break;
        default:
            break;
    }
    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView * header = (UITableViewHeaderFooterView *)view;
    
    UIFont * font = header.textLabel.font;
    headerFont = font;
    header.textLabel.textColor = [SenderCore sharedCore].stylePalette.secondaryTextColor;
}

#pragma mark - Setting Values

- (void)updateBlockedListCountLabel:(NSInteger)count
{
    blackListCount = (count >= 0) ? count : 0;
    lbBlockedUserCount.text = [NSString stringWithFormat:@"%lu",(unsigned long) count];
    lbBlockedUsersTitle.enabled = (count > 0);
}

- (void)customizeNavigationBar
{
    [self.navigationController.navigationBar setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
    if (self.leftBarButtonImage)
    {
        UIBarButtonItem * leftBarButton = [[UIBarButtonItem alloc] initWithImage:self.leftBarButtonImage
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(closeSettings)];
        self.navigationItem.leftBarButtonItem = leftBarButton;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}


- (void)updateWithSettings:(Settings *)settings
{
    [swSounds setOn:settings.sounds.boolValue];
    [swReadStatus setOn:settings.sendRead.boolValue];
    [swLocation setOn:settings.location.boolValue];
    [swNotificationsSound setOn:settings.notificationsSound.boolValue];
    [swNotificationsFlash setOn:settings.notificationsFlash.boolValue];
    [swNotificationsVibration setOn:settings.notificationsVibration.boolValue];
}

- (void)updateWithBlockedUsersCount:(NSInteger)blockedUsersCount
{
    [self updateBlockedListCountLabel:blockedUsersCount];
}

- (void)localize
{
    lbLocationTitle.text = SenderFrameworkLocalizedString(@"location_settings_title_ios", nil);
    lbNotificationsSoundTitle.text = SenderFrameworkLocalizedString(@"silent_notifications_ios", nil);
    lbNotificationsVibrationTitle.text = SenderFrameworkLocalizedString(@"vibro_notifications_ios", nil);
    lbNotificationsFlashTitle.text = SenderFrameworkLocalizedString(@"flash_notifications_ios", nil);
    lbReadStatusTitle.text = SenderFrameworkLocalizedString(@"send_read_ios", nil);
    lbSoundTitle.text = SenderFrameworkLocalizedString(@"sound_notifications_setting_btn", nil);
    lbBlockedUsersTitle.text = SenderFrameworkLocalizedString(@"blocked_users_ios", nil);
    lbClearHistoryTitle.text = SenderFrameworkLocalizedString(@"clear_history_ios", nil);
    lbDisableDeviceTitle.text = SenderFrameworkLocalizedString(@"disable_device_ios", nil);
    lbBitcoinWallet.text = SenderFrameworkLocalizedString(@"bitcoin_wallet", nil);
    lbMyDevicesTitle.text = SenderFrameworkLocalizedString(@"my_devices", nil);
}

#pragma mark - Actions

- (void)switchValueChanged:(id)sender
{
    if (sender == swReadStatus)
        [self.presenter changeSendReadStatusTo:swReadStatus.on];
    else if (sender == swSounds)
        [self.presenter changeSoundStatusTo:swSounds.on];
    else if (sender == swLocation)
        [self.presenter changeLocationMonitoringStatusTo:swLocation.on];
    else if (sender == swNotificationsSound)
        [self.presenter changeNotificationSoundTo:swNotificationsSound.on];
    else if (sender == swNotificationsVibration)
        [self.presenter changeVibrationStatusTo:swNotificationsVibration.on];
    else if (sender == swNotificationsFlash)
        [self.presenter changeFlashStatusTo:swNotificationsFlash.on];
}

- (void)clearHistory
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"clear_history_question_ios", nil)
                                                                              message:SenderFrameworkLocalizedString(@"clear_history_message_ios", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * clearAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"yes", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [self.presenter clearChatHistory];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"no", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alertController addAction:clearAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)requestMyDevicesForm
{
    [self.presenter showActiveDevices];
}


- (void)disableDevice
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"disable_device_title", nil)
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * disableAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"yes", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
                                                             [self.presenter disableDevice];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"no", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alertController addAction:disableAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)showBlockedUsers
{
    if (blackListCount)
        [self.presenter showBlockedUsers];
}

-(void)showPasswordForm
{
    [syncManager showPasswordInputFormWithTitle:SenderFrameworkLocalizedString(@"bitcoin_enter_password_title", nil)
                                        message:SenderFrameworkLocalizedString(@"bitcoin_enter_local_synchronization_password", nil)];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0)
    {
        if (indexPath.row == 3)
            [self showBlockedUsers];
        else if (indexPath.row == 4)
            [self showPasswordForm];
    }
    else if (indexPath.section == 2)
    {
        if (indexPath.row == 0)
            [self clearHistory];
        else if (indexPath.row == 1)
            [self disableDevice];
        else if (indexPath.row == 2)
            [self requestMyDevicesForm];
    }
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 1)
                [cell setAccessoryView:swReadStatus];
            else if (indexPath.row == 2)
                [cell setAccessoryView:swLocation];
            break;
        }
        case 1:
        {
            if (indexPath.row == 0)
                [cell setAccessoryView:swSounds];
            else if (indexPath.row == 1)
                [cell setAccessoryView:swNotificationsSound];
            else if (indexPath.row == 2)
                [cell setAccessoryView:swNotificationsVibration];
            else if (indexPath.row == 3)
                [cell setAccessoryView:swNotificationsFlash];
            break;
        }
        default:
            break;
    }
    cell.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    cell.contentView.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == bitcoinWalletCell && ![[SenderCore sharedCore] isBitcoinEnabled])
        return 0.0;

    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)showLocationNotAvailableWarning
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available", nil)
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];

    UIAlertAction * goToSettingsAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available_go_to_settings", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                }];
    [alert addAction:goToSettingsAction];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)updateWithViewModel:(Settings *)viewModel
{
    if (![self isViewLoaded]) return;
        [self updateWithSettings:viewModel];
}

- (void)closeSettings
{
    [self.presenter closeSettings];
}

#pragma mark - BitcoinPasswordManager Delegate

-(void)bitcoinSyncManagerWasCanceled
{

}

- (void)bitcoinSyncManagerDidFinishedCheckingPassword:(BOOL)isRightPassword
{
    if (isRightPassword)
    {
        [self.presenter showBitcoinWallet];
    }
    else
    {
        [syncManager showPasswordInputFormWithTitle:SenderFrameworkLocalizedString(@"bitcoin_entered_wrong_password", nil)
                                            message:SenderFrameworkLocalizedString(@"bitcoin_enter_password_message", nil)];
    }
}

- (void)showBitcoinSettings
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    UIStoryboard * settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle:NSBundle.senderFrameworkResourcesBundle];
    UIViewController * bitcoinSettings = [settingsStoryboard instantiateViewControllerWithIdentifier:@"BitcoinSettingsViewController"];
    [self.navigationController pushViewController:bitcoinSettings animated:YES];
}

#pragma mark - BitcoinPasswordManager Data Source

-(NSString *)bitcoinSyncManagerPasswordToCheck:(BitcoinSyncManager *)syncManager
{
    NSError * error;
    return [[[CoreDataFacade sharedInstance]getOwner]getPassword:&error];
}

#pragma mark - Others

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - ModalInNavigationWireframe Events Handler

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    UIImage *closeImage = [UIImage imageFromSenderFrameworkNamed:@"close"];
    self.leftBarButtonImage = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{

}

@end
