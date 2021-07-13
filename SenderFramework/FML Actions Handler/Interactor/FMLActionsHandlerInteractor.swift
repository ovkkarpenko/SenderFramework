//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol FMLActionsHandlerInteractorDelegate: class {
    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     needsUpdatedChatWithID chatID: String)
    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool
}

class FMLActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol {
    weak var presenter: FMLActionsHandlerPresenterProtocol?
    weak var delegate: FMLActionsHandlerInteractorDelegate?
    var dataManager: FMLActionsHandlerDataManagerProtocol
    var googleUserManager: GoogleUserManagerProtocol?
    var chat: Dialog!

    init(dataManager: FMLActionsHandlerDataManagerProtocol, googleUserManager: GoogleUserManagerProtocol?) {
        self.dataManager = dataManager
        self.googleUserManager = googleUserManager
    }

    func updateWith(chatID: String) {
        self.delegate?.fmlActionsHandlerInteractor(self, needsUpdatedChatWithID: chatID)
    }

    func handleFMLAction(_ action: [AnyHashable: Any], forForm form: PBConsoleView, actionField: PBSubviewFacade) {
        let actionsParser = FMLActionParser()
        guard let parsedAction = actionsParser.parseActionDictionary(action) else { return }
        switch parsedAction {
        case .goTo(let action): break
        case .openURL(let url): self.openURL(url)
        case .callPhone(let phone): self.callPhone(phone)
        case .requestRobot(let action): self.requestRobotWith(form: form, actionField: actionField, action: action)
        case .selectUser(let action): self.selectUserFor(form: form, actionField: actionField, action: action)
        case .scanQR: self.scanQRAndSendToServer()
        case .scanQRTo(let action): self.scanQRFor(form: form, actionField: actionField, action: action)
        case .sendBitcoin(let action): self.sendBitcoinWith(form: form, actionField: actionField, action: action)
        case .notarizeBitcoin(let action): break
        case .archiveBitcoin(let action): break
        case .share(let action): self.handleShareAction(action)
        case .showAsQR(let action): self.showActionAsQR(action)
        case .changeFullVersion(let action): self.changeFullVersionStateFor(form: form,
                                                                            actionField: actionField,
                                                                            action: action)
        case .copy(let action): self.handleCopyAction(action)
        case .submitOnChange(let action): self.submitForm(form, withAction: action, actionField: actionField)
        case .loadFile(let action): self.loadImageFor(form: form, actionField: actionField, action: action)
        case .googleAuth(let action): self.signInToGoogleFor(form: form, actionField: actionField, action: action)
        case .bitSignWithKey(let action): self.bitSignWith(form: form, actionField: actionField, action: action)
        case .sendLocation(let action): self.getLocation(form: form, actionField: actionField, action: action)
        }
    }

    func loadFileForForm(_ form: PBConsoleView, actionField: PBLoadFileView) {
        self.presenter?.takePhoto { _, image in
            guard let image = image, let imageData = UIImageJPEGRepresentation(image, 0.4) else { return }
            self.dataManager.uploadData(imageData) { url, error in
                guard error == nil, let url = url else { return }
                actionField.setImageURL(url, imageData: imageData)
            }
        }
    }

    func isAutoSubmitAction(_ actionDictionary: [AnyHashable: Any]) -> Bool {
        return (actionDictionary["autosubmit"] as? Bool) ?? false
    }

    func selectUserFor(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        let showAllContacts = !(action["reg"] as? Bool ?? false)
        var contacts = showAllContacts ? self.dataManager.getContacts() : self.dataManager.getSenderUsers()
        if showAllContacts { contacts = contacts.filter { $0.getPhoneFormatted(false).lenght() > 0 } }
        self.presenter?.selectFrom(contacts: contacts, allowsMultipleSelection: false) { selectedContacts in
            guard let selectedContact = selectedContacts.first else { return }
            form.setContact(selectedContact, forActionView: actionField, action: action)
            if self.isAutoSubmitAction(action) {
                self.submitForm(form, withAction: action, actionField: actionField)
            }
        }
    }

    func scanQRFor(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        self.presenter?.showQRScanner { scanResult in
            guard let qrString = scanResult else { return }
            form.setQRScanResult(qrString, forActionView: actionField, action: action)
            if self.isAutoSubmitAction(action) {
                self.submitForm(form, withAction: action, actionField: actionField)
            }
        }
    }

    func changeFullVersionStateFor(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        guard let isFullVersion = action["full"] as? Bool else { return }
        let chatIDToGo = action["chatId"]

        func actuallyChangeFullVersionState(newState: Bool) {
            self.presenter?.interactorWillChangeFullVersionState()
            self.dataManager.changeFullVersionStateTo(newFullVersionState: newState) { success, error in
                self.presenter?.interactorDidChangeFullVersionState()
                //TODO: Remove from here
                defer { actionField.setActive(true) }
                guard error == nil else {
                    self.presenter?.showFullVersionError(error!)
                    return
                }
                guard success else {
                    let unknownError = NSError(domain: "Cannot change full version state", code: 666)
                    self.presenter?.showFullVersionError(unknownError)
                    return
                }
                if let newChatID = chatIDToGo as? String {
                    self.updateWith(chatID: newChatID)
                }
            }
        }

        if isFullVersion {
            self.presenter?.showTermsAndConditions { areTermsConditionsAccepted in
                if areTermsConditionsAccepted {
                    actuallyChangeFullVersionState(newState: isFullVersion)
                } else {
                    actionField.setActive(true)
                }
            }
        } else {
            actuallyChangeFullVersionState(newState: isFullVersion)
        }
    }

    func submitForm(_ form: PBConsoleView, withAction action: [AnyHashable: Any], actionField: PBSubviewFacade?) {
        var action = action
        if let actionField = actionField,
           let fieldName = actionField.viewModel.name,
           let fieldValue = actionField.viewModel.val {
            action[fieldName] = fieldValue
        }
        guard let formData = form.submitInfo(withAction: action) else { return }
        self.dataManager.sendFormData(formData, completion: nil)
    }

    func sendForm(_ form: PBConsoleView, withAction action: [AnyHashable: Any], actionField: PBSubviewFacade) {
        self.submitForm(form, withAction: action, actionField: actionField)
    }

    func loadImageFor(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        self.presenter?.takePhoto { _, image in
            guard let image = image, let imageData = UIImageJPEGRepresentation(image, 0.4) else { return }
            self.dataManager.uploadData(imageData) { url, error in
                guard error == nil, let url = url else { return }
                form.setImageURL(url, imageData: imageData, forActionView: actionField, action: action)
            }
        }
    }

    func showActionAsQR(_ action: [AnyHashable: Any]) {
        guard let stringToShow = action["value"] as? String else { return }
        MWFMLStringParser.parseFMLString(stringToShow, forChat: self.chat) { parsedString in
            guard let parsedString = parsedString else { return }
            DispatchQueue.main.async { self.presenter?.showQRCodeWith(string: parsedString) }
        }
    }

    func handleCopyAction(_ action: [AnyHashable: Any]) {
        guard let stringToCopy = action["value"] as? String else { return }
        MWFMLStringParser.parseFMLString(stringToCopy, forChat: self.chat) { parsedString in
            guard let parsedString = parsedString else { return }
            DispatchQueue.main.async {
                let pasteBoard = UIKit.UIPasteboard.general
                pasteBoard.string = parsedString
                self.presenter?.textWasCopiedToClipboard()
            }
        }
    }

    func handleShareAction(_ action: [AnyHashable: Any]) {
        guard let stringToShare = action["value"] as? String else { return }
        MWFMLStringParser.parseFMLString(stringToShare, forChat: self.chat) { parsedString in
            guard let parsedString = parsedString else { return }
            DispatchQueue.main.async {
                self.presenter?.shareItems([parsedString])
            }
        }
    }

    func requestRobotWith(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        guard let robotInfo = form.robotInfo(withActionView: actionField, action: action) else { return }
        self.requestRobotWith(robotDictionary: robotInfo)
    }

    func requestRobotWith(robotDictionary: [AnyHashable: Any]) {
        guard let robotModel = CallRobotModel(actionDictionary: robotDictionary) else { return }
        self.callRobot(robotModel)
    }

    func callRobot(_ callRobotModel: CallRobotModel) {
        let shouldCallRobot: Bool
        if let delegate = self.delegate {
            shouldCallRobot = delegate.fmlActionsHandlerInteractor(self, shouldCallRobotWithModel: callRobotModel)
        } else {
            shouldCallRobot = true
        }

        guard shouldCallRobot else { return }

        if let robotChatID = callRobotModel.chatID {
            if robotChatID != self.chat.chatID { self.updateWith(chatID: robotChatID) }
        } else {
            callRobotModel.chatID = self.chat.chatID
        }
        self.dataManager.callRobotWith(model: callRobotModel, completion: nil)
    }

    func sendBitcoinWith(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        guard let bitcoinAddress = form.bitcoinAddress(forActionView: actionField, action: action),
              let bitcoinAmount = form.bitcoinAmount(forActionView: actionField, action: action) else {
            let error = NSError(domain: "Cannot get transaction data", code: 666)
            self.presenter?.showBitcoinSendingError(error)
            return
        }

        guard let ownerWallet = self.dataManager.getOwnerBitcoinWallet() else {
            let error = NSError(domain: "Cannot get owner's wallet", code: 666)
            self.presenter?.showBitcoinSendingError(error)
            return
        }

        let bitcoinManager = BitcoinManager()
        bitcoinManager.transferMoney(from: ownerWallet,
                                     toAddress: bitcoinAddress,
                                     withAmount: bitcoinAmount) { response, error in
            let defaultErrorText = SenderFrameworkLocalizedString("error_ios")
            let result = response?["result"] as? String ?? (error?.localizedDescription ?? defaultErrorText)
            guard let bitcoinTransactionResult = form.bitcoinTransactionResult(withAddress: bitcoinAddress,
                                                                               amount: bitcoinAmount,
                                                                               transactionResult: result,
                                                                               actionView: actionField,
                                                                               action: action) else { return }
            self.dataManager.sendFormData(bitcoinTransactionResult, completion: nil)
        }
    }

    func signInToGoogleFor(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        guard let googleUserManager = self.googleUserManager else {
            let localizedDescription = SenderFrameworkLocalizedString("google_sign_in_not_enabled")
            let error = NSError(domain: "Google sign in is not enabled",
                                code: 666,
                                userInfo: [NSLocalizedDescriptionKey: localizedDescription])
            self.presenter?.showGoogleSignInError(error)
            return
        }
        self.presenter?.getGoogleUser { googleUser, error in
            //TODO: Remove from here
            defer { actionField.setActive(true) }
            guard error == nil else { self.presenter?.showGoogleSignInError(error!); return }
            guard let googleUser = googleUser else {
                let localizedDescription = SenderFrameworkLocalizedString("google_sign_cannot_get_user")
                let error = NSError(domain: "Cannot get Google user",
                                    code: 666,
                                    userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                self.presenter?.showGoogleSignInError(error)
                return
            }

            googleUserManager.saveGoogleUser(googleUser) { success, error in
                guard error == nil else {
                    self.presenter?.showGoogleSignInError(error!)
                    return
                }
                guard success else {
                    let localizedDescription = SenderFrameworkLocalizedString("google_sign_cannot_save_user")
                    let error = NSError(domain: "Cannot save Google user",
                                        code: 666,
                                        userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                    self.presenter?.showGoogleSignInError(error)
                    return
                }

                form.setGoogleUser(googleUser, forActionView: actionField, forAction: action)
            }
        }
    }

    func bitSignWith(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        guard SenderCore.shared().isBitcoinEnabled else {
            let localizedDescription = SenderFrameworkLocalizedString("bit_sign_signing_error")
            let error = NSError(domain: "Cannot sign document. Bitcoin is disabled",
                                code: 666,
                                userInfo: [NSLocalizedDescriptionKey: localizedDescription])
            self.presenter?.showGoogleSignInError(error)
            return

        }
        guard let oldBase58Key = action["keyCrypted"] as? String, let publicKey = action["pubKey"] as? String else {
            let localizedDescription = SenderFrameworkLocalizedString("bit_sign_signing_error")
            let error = NSError(domain: "Cannot sign document. Wrong keys",
                                code: 666,
                                userInfo: [NSLocalizedDescriptionKey: localizedDescription])
            self.presenter?.showGoogleSignInError(error)
            return
        }

        let bitSignManager = BitSignManager()
        guard let signedKey = bitSignManager.signWithOldKey(oldKey: oldBase58Key, publicKey: publicKey) else {
            let localizedDescription = SenderFrameworkLocalizedString("bit_sign_signing_error")
            let error = NSError(domain: "Cannot sign document. Cannot generate new key",
                                code: 666,
                                userInfo: [NSLocalizedDescriptionKey: localizedDescription])
            self.presenter?.showGoogleSignInError(error)
            return
        }

        form.setSignedKey(signedKey, forActionView: actionField, forAction: action)
        self.submitForm(form, withAction: [:], actionField: actionField)
    }

    func getLocation(form: PBConsoleView, actionField: PBSubviewFacade, action: [AnyHashable: Any]) {
        self.presenter?.getLocation { location, _, description in
            form.setLocation(location, locationDescription: description, forActionView: actionField, action: action)
        }
    }

    func getLocationForForm(_ form: PBConsoleView, actionField: PBMapView) {
        self.presenter?.getLocation { location, _, description in
            actionField.setLocation(location, withDescription: description)
        }
    }

    func selectFromValues(_ values: [Any]?, forForm form: PBConsoleView, actionField: PBSelectedView) {
        guard let values = values else { return }
        self.presenter?.selectFromValues(values) { selectedValue in
            guard let valueDictionary = selectedValue as? [AnyHashable: Any] else { return }
            actionField.setSelectedValue(valueDictionary)
        }
    }

    func openURL(_ url: URL) {
        SenderCore.shared().application.openURL(url)
    }

    func scanQRAndSendToServer() {
        guard let chatID = self.chat.chatID else { return }
        self.presenter?.showQRScanner { scanResult in
            guard let qrString = scanResult else { return }
            self.dataManager.sendQRString(qrString, chatID: chatID, completion: nil)
        }
    }

    func callPhone(_ phone: String) {
        let phoneURLString = "telprompt://" + phone
        guard let phoneUrl = URL(string: phoneURLString) else { return }
        SenderCore.shared().application.openURL(phoneUrl)
    }
}
