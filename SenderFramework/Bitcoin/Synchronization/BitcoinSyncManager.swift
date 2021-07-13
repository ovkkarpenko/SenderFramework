//
//  BitcoinSyncManager.swift
//  SENDER
//
//  Created by Roman Serga on 19/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

let storyboardName = "BitcoinSynchronization"

let mainScreenID = "BitcoinSyncMainViewController"
let newWalletScreenID = "BitcoinSyncNewWalletViewController"
let importScreenID = "BitcoinSyncImportWalletViewController"
let exportScreenID = "BitcoinSyncExportWalletViewController"
let resolveConflictScreenID = "BitcoinResolveConflictViewController"

let passwordEnterScreenID = "BitcoinSyncPasswordEnterViewController"
let passwordCreateScreenID = "BitcoinSyncPasswordEnterViewController"

import UIKit

//MARK : - Protocols

@objc public protocol BitcoinSyncManagerDataSource {
    @objc optional func bitcoinSyncManagerPasswordToCheck(_ syncManager: BitcoinSyncManager) -> String
    @objc optional func bitcoinSyncManagerRemotePasswordToCheck(_ syncManager: BitcoinSyncManager) -> String
}

@objc public protocol BitcoinSyncManagerDelegate {

    @objc optional func bitcoinSyncManagerWasCanceled()
    @objc optional func bitcoinSyncManagerDidFinishedImportWithMnemonic(_ mnemonic: BTCMnemonic?, andError error: NSError?)
    @objc optional func bitcoinSyncManagerDidFinishedCreatingPassword(_ password: String)
    @objc optional func bitcoinSyncManagerDidFinishedCheckingPassword(_ isRightPassword: Bool)
    @objc optional func bitcoinSyncManagerNeedsGoToSettings()

    //Implement this method in your delegate, if BitcoinSyncManager doesn't have DataSource with implemented
    //bitcoinSyncManagerPasswordToCheck
    //If your class implements both of them, password will be treated as correct if at least one of them
    //returns true
    @objc optional func bitcoinSyncManagerIsPasswordRight(_ password: String) -> Bool
    @objc optional func bitcoinSyncManagerIsRemotePasswordRight(_ password: String) -> Bool
}

//MARK : - Screen Classes

open class BitcoinSyncScreen: UIViewController {
    var syncManager: BitcoinSyncManager?
}

open class BitcoinSyncStartScreen: BitcoinSyncScreen {}
open class BitcoinSyncNewWalletScreen: BitcoinSyncScreen {}
open class BitcoinSyncImportScreen: BitcoinSyncScreen {
    var oldAddress: String?
}

open class BitcoinSyncResolveConflictScreen: BitcoinSyncScreen {
    var remoteMnemonic: BTCMnemonic?
    var localMnemonic: BTCMnemonic?
    var cancelDisabled: Bool = false
}

open class BitcoinSyncExportScreen: BitcoinSyncScreen {
    var mnemonicToExport: BTCMnemonic?
}

open class BitcoinSyncPasswordEnterScreen: BitcoinSyncScreen {
    var disableCancel: Bool = false
    var promptString: String?
    var secondaryButtonTitle: String?
    func showAlert(_ alertString: String, completion: (() -> Void)? = nil ) {}

    var sequenceType: PasswordSequenceType!
    var sequenceState: PasswordSequenceState!
}

open class BitcoinSyncPasswordCheckScreen: BitcoinSyncPasswordEnterScreen {

}

open class BitcoinSyncPasswordCreateScreen: BitcoinSyncPasswordEnterScreen {

}

//MARK : - Sync Manager

public enum PasswordSequenceType {
    case checkPassword
    case createPassword
    case changePassword
    case importPassword
    case conflictResolving
    case createFromConflict
}

public enum PasswordSequenceState {
    case enteredNothing
    case enteredOldPassword
    case enteredNewPassword
    case enteredNewPasswordTwice
}

public enum PasswordEnterScreenType {
    case currentPassword(promptTitle: String?, cancelDisabled: Bool , secondaryButtonTitle: String?)
    case oldPassword(promptTitle: String?, cancelDisabled: Bool, secondaryButtonTitle: String?)
    case newPassword(promptTitle: String?, cancelDisabled: Bool, secondaryButtonTitle: String?)
    case repeatNewPassword(promptTitle: String?, cancelDisabled: Bool, secondaryButtonTitle: String?)
}

@objc open class BitcoinSyncManager: NSObject {

    fileprivate var storyboard: UIStoryboard
    unowned fileprivate(set) var rootViewController: UIViewController
    @objc open fileprivate(set) var mainNavigationController: UINavigationController

    @objc open weak var dataSource: BitcoinSyncManagerDataSource?
    @objc open weak var delegate: BitcoinSyncManagerDelegate?

    open var passwordSequenceType: PasswordSequenceType!
    open var passwordSequenceState: PasswordSequenceState!
    var firstStepPassword: String!
    var qrDisplayModule: QRDisplayModule?

    //MARK : Initialization

    @objc public init(rootViewController: UIViewController, andDelegate delegate: BitcoinSyncManagerDelegate? = nil) {
        self.rootViewController = rootViewController
        self.delegate = delegate
        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        self.storyboard = UIStoryboard(name: storyboardName, bundle: senderFrameworkBundle)
        self.mainNavigationController = UINavigationController()
        super.init()
        self.mainNavigationController.delegate = self
    }

    //MARK : Implementation

    fileprivate func showViewController(_ viewController: BitcoinSyncScreen) {
        viewController.syncManager = self
        if mainNavigationController.presentingViewController != nil {
            mainNavigationController.pushViewController(viewController, animated: true)
        } else {
            mainNavigationController.setViewControllers([viewController], animated: true)
            rootViewController.present(mainNavigationController, animated: true, completion: { () -> Void in
            })
        }
    }

    func cleanNavigationController() {
        mainNavigationController.dismiss(animated: false, completion: nil)
        mainNavigationController.viewControllers = []
    }
}

//MARK : - Wallet Creation
extension BitcoinSyncManager {
    @objc func startWalletCreation() {
        showNewWalletScreen(nil)
    }

    func showNewWalletScreen(_ sender: BitcoinSyncScreen?) {
        let actionSheet = UIAlertController(title: SenderFrameworkLocalizedString("bitcoin_create_new_alert_title", comment: ""), message: SenderFrameworkLocalizedString("bitcoin_create_new_alert_message", comment: ""), preferredStyle: .actionSheet)

        let createAction = UIAlertAction(title: SenderFrameworkLocalizedString("bitcoin_create_button_text", comment: ""),
                                         style: .destructive) { (_) -> Void in
            self.finishWithCreatingNewWallet(nil)
        }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel", comment: ""),
                                         style: .cancel) { (_) -> Void in
        }

        actionSheet.addAction(createAction)
        actionSheet.addAction(cancelAction)

        let presenter = rootViewController
        actionSheet.mw_safePresentIn(viewController: rootViewController, animated: true)
    }

    func finishWithCreatingNewWallet(_ sender: BitcoinSyncScreen?) {
        cleanNavigationController()
        let mnemonic = BTCMnemonic.randomMnemonic(withPassword: nil, andWordListType: .english)
        self.delegate?.bitcoinSyncManagerDidFinishedImportWithMnemonic?(mnemonic, andError: nil)
    }
}

//MARK : - Wallet Import
extension BitcoinSyncManager {
    @objc func startWalletImport(_ address: String?) {
        showImportScreen(address, sender: nil)
    }

    func showImportScreen(_ address: String?, sender: BitcoinSyncScreen?) {
        if let importScreen = storyboard.instantiateViewController(withIdentifier: importScreenID) as? BitcoinSyncImportScreen {
            importScreen.oldAddress = address
            showViewController(importScreen)
        }
    }

    func finishWithString(_ wordsString: String, sender: BitcoinSyncScreen?) {
        let mnemonic = BTCMnemonic(words: wordsString.components(separatedBy: " "),
                                   password: nil,
                                   wordListType: .english)
        finishWithMnemonic(mnemonic, sender: sender)
    }

    func finishWithMnemonic(_ mnemonic: BTCMnemonic?, sender: BitcoinSyncScreen?) {
        rootViewController.dismiss(animated: true) { () -> Void in
            self.cleanNavigationController()
            self.delegate?.bitcoinSyncManagerDidFinishedImportWithMnemonic?(mnemonic, andError: nil)
        }
    }
}

//MARK : - Wallet Export
extension BitcoinSyncManager: QRDisplayModuleDelegate {
    @objc func startWalletExport(_ mnemonic: BTCMnemonic) {
        showExportScreen(mnemonic, sender: nil)
    }

    func showExportScreen(_ mnemonic: BTCMnemonic, sender: BitcoinSyncScreen?) {
        guard let wordsString = (mnemonic.words as? [String])?.joined(separator: " ") else { return }
        self.qrDisplayModule = QRDisplayModule()
        let wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        self.qrDisplayModule?.presentWith(wireframe: wireframe,
                                          qrString: wordsString,
                                          forDelegate: self,
                                          completion: nil)
    }

    public func qrDisplayModuleDidCancel() {
        self.qrDisplayModule?.dismiss(completion: nil)
    }

}

//MARK : - Password Operations
extension BitcoinSyncManager {

    @objc open func startPasswordChecking() {
        let newSequenceType = PasswordSequenceType.checkPassword
        let newSequenceState = PasswordSequenceState.enteredNothing

        guard  (passwordSequenceState == nil || passwordSequenceState != newSequenceState) ||
                       (passwordSequenceState == nil || passwordSequenceType != newSequenceType) else { return }

        passwordSequenceType = newSequenceType
        passwordSequenceState = newSequenceState

        showPasswordEnterScreen(.currentPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_synchronization_password", comment: ""), cancelDisabled: false, secondaryButtonTitle: nil), sender: nil)
    }

    @objc open func startPasswordCreation() {
        let newSequenceType = PasswordSequenceType.createPassword
        let newSequenceState = PasswordSequenceState.enteredNothing

        guard  (passwordSequenceState == nil || passwordSequenceState != newSequenceState) ||
                       (passwordSequenceState == nil || passwordSequenceType != newSequenceType) else { return }

        passwordSequenceType = newSequenceType
        passwordSequenceState = newSequenceState
        showPasswordEnterScreen(.newPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: nil)
    }

    @objc open func startPasswordChanging() {
        let newSequenceType = PasswordSequenceType.changePassword
        let newSequenceState = PasswordSequenceState.enteredNothing

        guard  (passwordSequenceState == nil || passwordSequenceState != newSequenceState) ||
                       (passwordSequenceState == nil || passwordSequenceType != newSequenceType) else { return }

        passwordSequenceType = newSequenceType
        passwordSequenceState = newSequenceState
        showPasswordEnterScreen(.oldPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_old_password", comment: ""), cancelDisabled: false, secondaryButtonTitle: nil), sender: nil)
    }

    @objc open func startPasswordImport() {
        let newSequenceType = PasswordSequenceType.importPassword
        let newSequenceState = PasswordSequenceState.enteredNothing

        guard  (passwordSequenceState == nil || passwordSequenceState != newSequenceState) ||
                       (passwordSequenceState == nil || passwordSequenceType != newSequenceType) else { return }

        passwordSequenceType = newSequenceType
        passwordSequenceState = newSequenceState
        showPasswordEnterScreen(.currentPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_synchronization_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: SenderFrameworkLocalizedString("bitcoin_create_new_alert_title", comment: "")), sender: nil)
    }

    fileprivate func getPasswordScreen(_ promptString: String,
                                       secondaryActionTitle: String? = nil,
                                       disableCancel: Bool = false) -> BitcoinSyncPasswordEnterScreen? {
        if let passwordScreen = storyboard.instantiateViewController(withIdentifier: passwordEnterScreenID) as? BitcoinSyncPasswordEnterScreen {
            passwordScreen.promptString = promptString
            passwordScreen.disableCancel = disableCancel
            passwordScreen.secondaryButtonTitle = secondaryActionTitle
            return passwordScreen
        }
        return nil
    }

    open func showPasswordEnterScreen(_ type: PasswordEnterScreenType,
                                      sender: BitcoinSyncScreen?,
                                      secondaryActionTitle: String? = nil,
                                      disableCancel: Bool = false) {

        let disableCancel: Bool
        let title: String?
        let secondaryAction: String?

        switch type {
        case .currentPassword(let promptTitle, let cancelDisabled, let secondaryButtonTitle):
            disableCancel = cancelDisabled
            secondaryAction = secondaryButtonTitle
            title = promptTitle
        case .oldPassword(let promptTitle, let cancelDisabled, let secondaryButtonTitle):
            disableCancel = cancelDisabled
            secondaryAction = secondaryButtonTitle
            title = promptTitle
        case .newPassword(let promptTitle, let cancelDisabled, let secondaryButtonTitle):
            disableCancel = cancelDisabled
            secondaryAction = secondaryButtonTitle
            title = promptTitle
        case .repeatNewPassword(let promptTitle, let cancelDisabled, let secondaryButtonTitle):
            disableCancel = cancelDisabled
            secondaryAction = secondaryButtonTitle
            title = promptTitle
        }

        if let passwordScreen = getPasswordScreen(title ?? "",
                                                  secondaryActionTitle: secondaryAction,
                                                  disableCancel: disableCancel) {
            passwordScreen.sequenceType = self.passwordSequenceType
            passwordScreen.sequenceState = self.passwordSequenceState
            showViewController(passwordScreen)
        }
    }

    @objc public func showPasswordInputFormWithTitle(_ title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let confirmAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios", comment: ""),
                                          style: .cancel) { [weak delegate = self.delegate] (_) -> Void in

            if let enteredPassword = alertController.textFields?[0].text {
                delegate?.bitcoinSyncManagerDidFinishedCheckingPassword?(self.compareToOldPassword(enteredPassword))
            }
        }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel", comment: ""),
                                         style: .default) { [weak delegate = self.delegate] (_) -> Void in
            delegate?.bitcoinSyncManagerWasCanceled?()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)

        alertController.addTextField { (textField) -> Void in
            textField.isSecureTextEntry = true
            textField.placeholder = SenderFrameworkLocalizedString("bitcoin_enter_password_textfield_placeholder",
                                                                   comment: "")
        }

        alertController.mw_safePresentIn(viewController: rootViewController, animated: true)
    }

    @objc func showNeedImportAlert () {
        let actionSheet = UIAlertController(title: SenderFrameworkLocalizedString("bitcoin_need_sync_alert_title", comment: ""),
                                            message: SenderFrameworkLocalizedString("bitcoin_need_sync_alert_message", comment: ""),
                                            preferredStyle: .actionSheet)

        let createAction = UIAlertAction(title: SenderFrameworkLocalizedString("bitcoin_need_sync_go_to_settings", comment: ""),
                                         style: .destructive) { (_) -> Void in
            self.goToSettings()
        }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("bitcoin_need_sync_later", comment: ""),
                                         style: .cancel) { (_) -> Void in
        }

        actionSheet.addAction(createAction)
        actionSheet.addAction(cancelAction)

        let presenter = mainNavigationController.topViewController ?? mainNavigationController
        actionSheet.mw_safePresentIn(viewController: presenter, animated: true)
    }

    open func secondaryButtonPressedOnPasswordScreen(_ sender: BitcoinSyncPasswordEnterScreen?) {
        switch passwordSequenceType as PasswordSequenceType {
        case .importPassword:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:

                let actionSheet = UIAlertController(title: SenderFrameworkLocalizedString("bitcoin_create_new_alert_title", comment: ""),
                                                    message: SenderFrameworkLocalizedString("bitcoin_create_new_alert_message", comment: ""), preferredStyle: .actionSheet)

                let createAction = UIAlertAction(title: SenderFrameworkLocalizedString("bitcoin_create_button_text", comment: ""),
                                                 style: .destructive) { (_) -> Void in
                    self.passwordSequenceState = .enteredOldPassword
                    self.showPasswordEnterScreen(.newPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: sender)
                }

                let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel", comment: ""),
                                                 style: .cancel) { (_) -> Void in
                }

                actionSheet.addAction(createAction)
                actionSheet.addAction(cancelAction)

                let presenter = mainNavigationController.topViewController ?? mainNavigationController
                actionSheet.mw_safePresentIn(viewController: presenter, animated: true)

            case .enteredOldPassword:
                passwordSequenceState = .enteredNothing
                mainNavigationController.popViewController(animated: true)
            default: break
            }
        default:
            break
        }
    }

    open func submitPassword(_ password: String, sender: BitcoinSyncPasswordEnterScreen?) {
        guard password.characters.count >= 4 else {
            sender?.showAlert(SenderFrameworkLocalizedString("wrong_bitcoin_password_format", comment: ""))
            return
        }
        switch passwordSequenceType as PasswordSequenceType {
        case .checkPassword:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                finishCheckingPassword(compareToOldPassword(password), sender: sender)
                passwordSequenceState = .enteredOldPassword
            default:
                //Impossible Cases
                break
            }
        case .createPassword:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                firstStepPassword = password
                passwordSequenceState = .enteredNewPassword
                showPasswordEnterScreen(.repeatNewPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_repeat_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: sender)
            case .enteredNewPassword:
                if compareToFirstStepPassword(password) {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredNewPasswordTwice
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_passwords_not_match", comment: ""), completion: {[unowned mainNavigationController = self.mainNavigationController] () -> Void in
                        self.passwordSequenceState = .enteredNothing
                        mainNavigationController.popViewController(animated: true)
                    })
                }
            default:
                //Impossible Case
                break
            }
        case .changePassword:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                if compareToOldPassword(password) {
                    passwordSequenceState = .enteredOldPassword
                    showPasswordEnterScreen(.newPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_new_password", comment: ""), cancelDisabled: false, secondaryButtonTitle: nil), sender: sender)
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_wrong_password", comment: ""),
                                      completion: { () -> Void in
                        self.cancelOperationSequence()
                    })
                }
            case .enteredOldPassword:
                firstStepPassword = password
                passwordSequenceState = .enteredNewPassword
                showPasswordEnterScreen(.repeatNewPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_repeat_new_password", comment: ""), cancelDisabled: false, secondaryButtonTitle: nil), sender: sender)
            case .enteredNewPassword:
                if compareToFirstStepPassword(password) {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredNewPasswordTwice
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_passwords_not_match", comment: ""), completion: {[unowned mainNavigationController = self.mainNavigationController] () -> Void in
                        self.passwordSequenceState = .enteredOldPassword
                        mainNavigationController.popViewController(animated: true)
                    })
                }
            default:
                break
            }

        case .importPassword:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                let passwordIsRight = compareToOldPassword(password)
                if passwordIsRight {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredOldPassword
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_wrong_password", comment: ""))
                }
            case .enteredOldPassword:
                firstStepPassword = password
                passwordSequenceState = .enteredNewPassword
                showPasswordEnterScreen(.repeatNewPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_repeat_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: sender)
            case .enteredNewPassword:
                if compareToFirstStepPassword(password) {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredNewPasswordTwice
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_passwords_not_match", comment: ""), completion: {[unowned mainNavigationController = self.mainNavigationController] () -> Void in
                        self.passwordSequenceState = .enteredOldPassword
                        mainNavigationController.popViewController(animated: true)
                    })
                }
            default:
                break
            }

        case .conflictResolving:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                let passwordIsRight = compareToOldPassword(password)
                if passwordIsRight {
                    finishCheckingPassword(passwordIsRight, sender: sender)
                    passwordSequenceState = .enteredOldPassword
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_wrong_password", comment: ""))
                }
            case .enteredOldPassword:
                if compareToRemotePassword(password) {
                    finishCreatingPassword(password, sender: sender)
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_wrong_password", comment: ""))
                }
            case .enteredNewPassword:
                if compareToFirstStepPassword(password) {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredNewPasswordTwice
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_passwords_not_match", comment: ""), completion: {[unowned mainNavigationController = self.mainNavigationController] () -> Void in
                        self.passwordSequenceState = .enteredOldPassword
                        mainNavigationController.popViewController(animated: true)
                    })
                }
            default:
                break
            }
        case .createFromConflict:
            switch passwordSequenceState as PasswordSequenceState {
            case .enteredNothing:
                if compareToOldPassword(password) {
                    passwordSequenceState = .enteredOldPassword
                    showPasswordEnterScreen(.newPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: sender)
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_wrong_password", comment: ""), completion: { () -> Void in
                        self.cancelOperationSequence()
                    })
                }
            case .enteredOldPassword:
                firstStepPassword = password
                passwordSequenceState = .enteredNewPassword
                showPasswordEnterScreen(.repeatNewPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_repeat_new_password", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: sender)
            case .enteredNewPassword:
                if compareToFirstStepPassword(password) {
                    finishCreatingPassword(password, sender: sender)
                    passwordSequenceState = .enteredNewPasswordTwice
                } else {
                    sender?.showAlert(SenderFrameworkLocalizedString("bitcoin_entered_passwords_not_match", comment: ""), completion: {[unowned mainNavigationController = self.mainNavigationController] () -> Void in
                        self.passwordSequenceState = .enteredOldPassword
                        mainNavigationController.popViewController(animated: true)
                    })
                }
            default:
                break
            }
        }
    }

    fileprivate func compareToFirstStepPassword(_ password: String) -> Bool {
        return password == firstStepPassword
    }

    fileprivate func compareToOldPassword(_ password: String) -> Bool {
        return (dataSource?.bitcoinSyncManagerPasswordToCheck?(self) == password) ||
               (delegate?.bitcoinSyncManagerIsPasswordRight?(password) != nil ? (delegate?.bitcoinSyncManagerIsPasswordRight?(password))!: false)
    }

    fileprivate func compareToRemotePassword(_ password: String) -> Bool {
        return (dataSource?.bitcoinSyncManagerRemotePasswordToCheck?(self) == password) ||
                (delegate?.bitcoinSyncManagerIsRemotePasswordRight?(password) != nil ? (delegate?.bitcoinSyncManagerIsRemotePasswordRight?(password))!: false)
    }

    func goToSettings() {
        cleanNavigationController()
        self.delegate?.bitcoinSyncManagerNeedsGoToSettings?()
    }
}

//MARK : - Finishing Sequences
extension BitcoinSyncManager {

    open func finishCheckingPassword(_ isRightPassword: Bool, sender: BitcoinSyncScreen?) {
        rootViewController.dismiss(animated: true) { () -> Void in
            self.passwordSequenceType = nil
            self.passwordSequenceState = nil

            self.cleanNavigationController()

            //CompletionBlock for keyboardHiding animation
            CATransaction.setCompletionBlock {
                self.delegate?.bitcoinSyncManagerDidFinishedCheckingPassword?(isRightPassword)
            }
        }
    }

    open func finishCreatingPassword(_ password: String, sender: BitcoinSyncScreen?) {
        rootViewController.dismiss(animated: true) { () -> Void in
            self.passwordSequenceType = nil
            self.passwordSequenceState = nil

            self.cleanNavigationController()

            //CompletionBlock for keyboardHiding animation
            CATransaction.setCompletionBlock {
                self.delegate?.bitcoinSyncManagerDidFinishedCreatingPassword?(password)
            }
        }
    }

    open func cancelOperationSequence() {
        rootViewController.dismiss(animated: true) { () -> Void in
            self.passwordSequenceType = nil
            self.passwordSequenceState = nil

            self.cleanNavigationController()

            //CompletionBlock for keyboardHiding animation
            CATransaction.setCompletionBlock {
                self.delegate?.bitcoinSyncManagerWasCanceled?()
            }
        }
    }
}

//MARK : - Resolving Conflicts
extension BitcoinSyncManager {

    @objc open func startCurrentPasswordCheckingForConflict() {
        passwordSequenceType = .conflictResolving
        passwordSequenceState = .enteredNothing
        showPasswordEnterScreen(.currentPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_need_sync_alert_message", comment: ""),
                                                 cancelDisabled: true,
                                                 secondaryButtonTitle: nil),
                                sender: nil)
    }

    @objc open func startRemotePasswordChecking() {
        passwordSequenceType = .conflictResolving
        passwordSequenceState = .enteredOldPassword
        showPasswordEnterScreen(.currentPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_enter_remote_synchronization_password", comment: ""),
                                                 cancelDisabled: true,
                                                 secondaryButtonTitle: nil),
                                sender: nil)
    }

    @objc func startWalletChoosing(_ remoteMnemonic: BTCMnemonic, localMnemonic: BTCMnemonic) {
        if let migrationScreen = storyboard.instantiateViewController(withIdentifier: resolveConflictScreenID) as? BitcoinSyncResolveConflictScreen {
            migrationScreen.remoteMnemonic = remoteMnemonic
            migrationScreen.localMnemonic = localMnemonic
            showViewController(migrationScreen)
        }
    }

    @objc func startWalletChoosingForConflict(_ remoteMnemonic: BTCMnemonic, localMnemonic: BTCMnemonic) {
        if let migrationScreen = storyboard.instantiateViewController(withIdentifier: resolveConflictScreenID) as? BitcoinSyncResolveConflictScreen {
            migrationScreen.remoteMnemonic = remoteMnemonic
            migrationScreen.localMnemonic = localMnemonic
            migrationScreen.cancelDisabled = true
            showViewController(migrationScreen)
        }
    }

    @objc open func startRemotePasswordCheckingForDefaultWallet() {
        passwordSequenceType = .conflictResolving
        passwordSequenceState = .enteredOldPassword
        showPasswordEnterScreen(.currentPassword(promptTitle: SenderFrameworkLocalizedString("bitcoin_need_sync_default_alert_message", comment: ""), cancelDisabled: true, secondaryButtonTitle: nil), sender: nil)
    }
}

extension BitcoinSyncManager: UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        guard let passwordScreen = viewController as? BitcoinSyncPasswordEnterScreen else { return }
        self.passwordSequenceType = passwordScreen.sequenceType
        self.passwordSequenceState = passwordScreen.sequenceState
    }
}
