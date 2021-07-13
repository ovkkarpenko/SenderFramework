//
//  SenderFramework.h
//  SenderFramework
//
//  Created by Valentin Dumareckii on 9/19/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for SenderFramework.
FOUNDATION_EXPORT double SenderFrameworkVersionNumber;

//! Project version string for SenderFramework.
FOUNDATION_EXPORT const unsigned char SenderFrameworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SenderFramework/PublicHeader.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

//General files
#import <SenderFramework/SenderCore.h>
#import <SenderFramework/SenderNotifications.h>
#import <SenderFramework/SenderFrameworkGlobals.h>
#import <SenderFramework/UnreadMessagesCounter.h>
#import <SenderFramework/ServerFacade.h>
#import <SenderFramework/MWLocationFacade.h>
#import <SenderFramework/MWAlertFacade.h>

//Data Base
#import <SenderFramework/CoreDataFacade.h>
#import <SenderFramework/Owner.h>
#import <SenderFramework/Dialog.h>
#import <SenderFramework/Message.h>
#import <SenderFramework/Contact.h>
#import <SenderFramework/Item.h>
#import <SenderFramework/File.h>
#import <SenderFramework/Settings.h>
#import <SenderFramework/DialogSetting.h>
#import <SenderFramework/CompanyCard+CoreDataClass.h>
#import <SenderFramework/ChatMember+CoreDataClass.h>
#import <SenderFramework/MessagesGap.h>

//Categories
#import <SenderFramework/UIImage+SenderFrameworkLoading.h>
#import <SenderFramework/NSBundle+SenderFrameworkLoading.h>
#import <SenderFramework/UIAlertView+CompletionHandler.h>
#import <SenderFramework/NSString+ConvertToLatin.h>
#import <SenderFramework/UIStoryboard+SenderFrameworkLoading.h>
#import <SenderFramework/NSString+EmojiHelpers.h>
#import <SenderFramework/UIView+MWSubviews.h>
#import "NSURL+MW_PercentEscapes.h"

//Views related files
#import <SenderFramework/EntityViewModel.h>
#import <SenderFramework/ActionCellModel.h>
#import <SenderFramework/GlobalSearchContactViewModel.h>
#import "ChatListChatViewModel.h"
#import <SenderFramework/ContactViewModel.h>
#import <SenderFramework/WelcomeViewController.h>
#import <SenderFramework/RegistrationViewController.h>
#import <SenderFramework/EnterPhoneViewController.h>
#import <SenderFramework/WaitForConfirmViewController.h>
#import <SenderFramework/EnterOTPViewController.h>
#import <SenderFramework/EnterNameViewController.h>
#import <SenderFramework/AddPhotoViewController.h>
#import <SenderFramework/WaitForIVRViewController.h>
#import <SenderFramework/ChatListViewController.h>
#import <SenderFramework/UserProfileViewController.h>
#import <SenderFramework/SettingsViewController.h>
#import <SenderFramework/QRDisplayViewController.h>
#import <SenderFramework/AddContactViewController.h>
#import <SenderFramework/PBConsoleConstants.h>
#import <SenderFramework/ChatPickerViewController.h>
#import <SenderFramework/SuperChatListViewController.h>
#import <SenderFramework/ChatPickerManager.h>
#import <SenderFramework/ChatPickerOneCompanyViewController.h>
#import <SenderFramework/ChatPickerManagerOneCompany.h>
#import <SenderFramework/PBConsoleManager.h>
#import <SenderFramework/MW_PSPDFThreadSafeMutableDictionary.h>
#import <SenderFramework/MWFMLStringParser.h>
#import <SenderFramework/MWMessageView.h>
#import <SenderFramework/MovieViewController.h>
#import <SenderFramework/SBCoordinator.h>
#import <SenderFramework/ImagePresenter.h>
#import <SenderFramework/ComplainPopUp.h>
#import <SenderFramework/ValueSelectTableViewController.h>

//Bitcoin
#import <CoreBitcoin/BTCMnemonic.h>
#import <SenderFramework/BitcoinWallet.h>
#import <SenderFramework/BitcoinManager.h>
#import <CoreBitcoin/BTCTransactionOutput.h>
#import <CoreBitcoin/BTCBase58.h>
#import <CoreBitcoin/BTCKeychain.h>

//TODO: SHOULDN'T BE HERE
#import <SenderFramework/SecGenerator.h>
#import <SenderFramework/SenderRequestBuilder.h>
#import <SenderFramework/ParamsFacade.h>
#import <SenderFramework/ECCWorker.h>
#import <SenderFramework/CometController.h>
#import <SenderFramework/SenderRequestBuilder.h>
#import <SenderFramework/AddressBook.h>
#import <SenderFramework/MWMessagesCryptography.h>
#import <SenderFramework/CameraManager.h>
#import <SenderFramework/VideoManager.h>
#import <SenderFramework/MWKeyboardListener.h>
#import <SenderFramework/LogerDBController.h>
#import <SenderFramework/MWLastActiveChatCoordinator.h>

#pragma clang diagnostic pop
