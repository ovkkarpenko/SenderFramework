//
//  SettingsViewController.h
//  SENDER
//
//  Created by Eugene on 11/4/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BitcoinSyncManagerDelegate;
@protocol BitcoinSyncManagerDataSource;

@protocol SettingsViewProtocol;
@protocol SettingsPresenterProtocol;

@protocol ModalInNavigationWireframeEventsHandler;

@class BitcoinSyncManager;
@class Settings;

@interface SettingsViewController : UITableViewController <UIActionSheetDelegate,
                                                           UINavigationControllerDelegate ,
                                                           UIImagePickerControllerDelegate,
                                                           UIScrollViewDelegate,
                                                           UITableViewDataSource,
                                                           UITableViewDelegate,
                                                           BitcoinSyncManagerDelegate,
                                                           BitcoinSyncManagerDataSource,
                                                           SettingsViewProtocol,
                                                           ModalInNavigationWireframeEventsHandler>
{
    //General Section

    __weak IBOutlet UITableViewCell * userInfoCell;
    
    __weak IBOutlet UILabel     * lbReadStatusTitle;
    UISwitch    * swReadStatus;

    __weak IBOutlet UILabel     * lbLocationTitle;
    UISwitch    * swLocation;

    __weak IBOutlet UILabel     * lbBlockedUsersTitle;
    __weak IBOutlet UILabel     * lbBlockedUserCount;

    __weak IBOutlet UILabel     * lbBitcoinWallet;
    __weak IBOutlet UITableViewCell * bitcoinWalletCell;

    //Sound Section

    __weak IBOutlet UILabel     * lbSoundTitle;
    UISwitch    * swSounds;

    __weak IBOutlet UILabel     * lbNotificationsSoundTitle;
    UISwitch    * swNotificationsSound;

    __weak IBOutlet UILabel     * lbNotificationsVibrationTitle;
    UISwitch    * swNotificationsVibration;

    __weak IBOutlet UILabel     * lbNotificationsFlashTitle;
    UISwitch    * swNotificationsFlash;
    
    //Reset Section
    
    __weak IBOutlet UILabel     * lbDisableDeviceTitle;
    __weak IBOutlet UILabel     * lbClearHistoryTitle;
    __weak IBOutlet UILabel     * lbMyDevicesTitle;

    BitcoinSyncManager * syncManager;
    UIFont * headerFont;
}

@property (nonatomic, strong, nullable) UIImage * leftBarButtonImage;
@property (nonatomic, strong, nullable) id<SettingsPresenterProtocol> presenter;

- (void)customizeNavigationBar;

- (void)updateWithSettings:(Settings *)settings;
- (void)localize;
- (void)switchValueChanged:(id)sender;
- (void)initSwitches;
- (void)disableDevice;
- (void)showPasswordForm;
- (void)showBlockedUsers;
- (void)clearHistory;
- (void)requestMyDevicesForm;
- (void)showBitcoinSettings;

@end
