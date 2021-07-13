//
// Created by Roman Serga on 24/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc open class SenderUI: NSObject, SenderUIProtocol {

    var rootViewController: UINavigationController
    var chatModule: ChatModuleProtocol?
    public var externalSenderUI: SenderUIProtocol?

    private var externalUI: SenderUIProtocol {
        return self.externalSenderUI ?? self
    }

    @objc public init(rootViewController: UINavigationController) {
        self.rootViewController = rootViewController
    }

    @objc open func showMainScreenAnimated(_ animated: Bool) -> MainScreenModuleProtocol {
        let addContactModule = AddContactModule()

        let qrScannerModule = QRScannerModule()
        let chatListModule = ChildChatListModule(addContactModule: addContactModule,
                                                 qrScannerModule: qrScannerModule,
                                                 senderUI: self.externalUI)

        let serverQRScannerModule = ChildQRServerScannerModule()
        let qrDisplayModule = ChildQRDisplayModule()
        let qrScreenModule = QRScreenModule(qrScannerModule: serverQRScannerModule, qrDisplayModule: qrDisplayModule)
        let userProfileModule = ChildUserProfileModule(qrScreenModule: qrScreenModule, senderUI: self.externalUI)
        let mainScreenModule = MainScreenModule(chatListModule: chatListModule,
                                                userProfileModule: userProfileModule)

        let containerWireframe = SetToNavigationWireframe(rootView: self.rootViewController)
        containerWireframe.animatedPresentation = animated
        mainScreenModule.presentWith(wireframe: containerWireframe, completion: nil)
        return mainScreenModule
    }

    @objc open func showChatScreenWith(chat: Dialog,
                                       actions: [[String: AnyObject]]?,
                                       options: [String: Any]?,
                                       animated: Bool,
                                       modally: Bool,
                                       delegate: ChatModuleDelegate?) -> ChatModuleProtocol? {
        guard let presentationModel = ChatPresentationModel(chat: chat) else { return nil }
        presentationModel.actions = actions
        presentationModel.options = options

        return self.showChatScreenWith(presentationModel: presentationModel,
                                       animated: animated,
                                       modally: modally,
                                       delegate: delegate)
    }

    @objc open func showChatScreenWith(chatID: String,
                                       actions: [[String: AnyObject]]?,
                                       options: [String: Any]?,
                                       animated: Bool,
                                       modally: Bool,
                                       delegate: ChatModuleDelegate?) -> ChatModuleProtocol {
        let presentationModel = ChatPresentationModel(chatID: chatID)
        presentationModel.actions = actions
        presentationModel.options = options

        return self.showChatScreenWith(presentationModel: presentationModel,
                                       animated: animated,
                                       modally: modally,
                                       delegate: delegate)
    }

    @objc open func showChatWith(remoteNotification: [AnyHashable: Any],
                                 animated: Bool,
                                 modally: Bool,
                                 delegate: ChatModuleDelegate?) -> ChatModuleProtocol? {
        guard let chatID = remoteNotification["ci"] as? String, !chatID.isEmpty else { return nil }
        return self.showChatScreenWith(chatID: chatID,
                                       actions: nil,
                                       options: nil,
                                       animated: animated,
                                       modally: modally,
                                       delegate: delegate)
    }

    fileprivate func showChatScreenWith(presentationModel: ChatPresentationModelProtocol,
                                        animated: Bool,
                                        modally: Bool,
                                        delegate: ChatModuleDelegate?) -> ChatModuleProtocol {
        let oldChatModule = self.chatModule

        let addToChatModule = AddToChatModule()
        let entityPickerModule = EntityPickerModule()
        let qrScannerModule = QRScannerModule()
        let qrDisplayModule = QRDisplayModule()
        let termsConditionsModule = TermsConditionsModule()

        let chatModule = ChatModule(addToChatModule: addToChatModule,
                                    entityPickerModule: entityPickerModule,
                                    qrScannerModule: qrScannerModule,
                                    qrDisplayModule: qrDisplayModule,
                                    termsConditionsModule: termsConditionsModule,
                                    senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        chatModule.presentWith(wireframe: wireframe,
                               model: presentationModel,
                               forDelegate: delegate) {
            oldChatModule?.dismissWithChildModules(completion: nil)
            self.chatModule = chatModule

            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    chatModule.senderUI = externalSenderUI
                }
            }
        }
        return chatModule
    }

    @objc open func showRobotScreenWith(model: CallRobotModelProtocol,
                                        animated: Bool,
                                        modally: Bool,
                                        delegate: ChatModuleDelegate?) -> CallRobotModuleProtocol? {
        let oldChatModule = self.chatModule

        let addToChatModule = AddToChatModule()
        let entityPickerModule = EntityPickerModule()
        let qrScannerModule = QRScannerModule()
        let qrDisplayModule = QRDisplayModule()
        let termsConditionsModule = TermsConditionsModule()

        let callRobotModule = CallRobotModule(addToChatModule: addToChatModule,
                                              entityPickerModule: entityPickerModule,
                                              qrScannerModule: qrScannerModule,
                                              qrDisplayModule: qrDisplayModule,
                                              termsConditionsModule: termsConditionsModule,
                                              senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        callRobotModule.presentWith(wireframe: wireframe,
                                    callRobotModel: model,
                                    forDelegate: delegate) {
            oldChatModule?.dismissWithChildModules(completion: nil)
            self.chatModule = callRobotModule

            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    callRobotModule.senderUI = externalSenderUI
                }
            }
        }

        return callRobotModule
    }

    @objc open func showChatList(animated: Bool,
                                 modally: Bool,
                                 forDelegate delegate: ChatListModuleDelegate?) -> ChatListModuleProtocol {
        let addContactModule = AddContactModule()
        let qrScannerModule = QRScannerModule()
        let chatListModule = ChildChatListModule(addContactModule: addContactModule,
                                                 qrScannerModule: qrScannerModule,
                                                 senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        chatListModule.presentWith(wireframe: wireframe, forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    chatListModule.senderUI = externalSenderUI
                }
            }
        }
        return chatListModule
    }

    @objc open func showUserProfile(animated: Bool,
                                    modally: Bool,
                                    forDelegate delegate: UserProfileModuleDelegate?) -> UserProfileModuleProtocol {
        let serverQRScannerModule = ChildQRServerScannerModule()
        let qrDisplayModule = ChildQRDisplayModule()
        let qrScreenModule = QRScreenModule(qrScannerModule: serverQRScannerModule, qrDisplayModule: qrDisplayModule)
        let userProfileModule = ChildUserProfileModule(qrScreenModule: qrScreenModule, senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        userProfileModule.presentWith(wireframe: wireframe, forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    userProfileModule.senderUI = externalSenderUI
                }
            }
        }
        return userProfileModule
    }

    @objc open func showSettings(animated: Bool,
                                 modally: Bool,
                                 forDelegate delegate: SettingsModuleDelegate?) -> SettingsModuleProtocol {
        guard let settings = CoreDataFacade.sharedInstance().getOwner().settings else {
            fatalError("Cannot get settings")
        }

        let blockedUsersModule = BlockedUsersModule()
        let bitcoinSettingsModule = BitcoinSettingsModule()
        let settingsModule = SettingsModule(blockedUsersModule: blockedUsersModule,
                                            senderUI: self.externalUI,
                                            bitcoinSettingsModule: bitcoinSettingsModule)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        settingsModule.presentWith(wireframe: wireframe,
                                   settings: settings,
                                   forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    settingsModule.senderUI = externalSenderUI
                }
            }
        }
        return settingsModule
    }
    
    @objc open func getDialogWithID(_ chatID: String) -> Dialog? {
        return CoreDataFacade.sharedInstance().dialog(withChatIDIfExist: chatID)
    }

    @objc open func showContactPageFor(chat: Dialog,
                                       animated: Bool,
                                       modally: Bool,
                                       forDelegate delegate: ChatSettingsModuleDelegate?)
                    -> ChatSettingsModuleProtocol {
        let addToChatModule = AddToChatModule()
        let chatSettingsModule = P2PChatSettingsModule(addToChatModule: addToChatModule, senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated

        chatSettingsModule.presentWith(wireframe: wireframe,
                                       chat: chat,
                                       forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    chatSettingsModule.senderUI = externalSenderUI
                }
            }
        }
        return chatSettingsModule
    }

    @objc open func showCompanyPageFor(chat: Dialog,
                                       animated: Bool,
                                       modally: Bool,
                                       forDelegate delegate: ChatSettingsModuleDelegate?)
                    -> ChatSettingsModuleProtocol {
        let addToChatModule = AddToChatModule()
        let entityPickerModule = EntityPickerModule()
        let qrScannerModule = QRScannerModule()
        let qrDisplayModule = QRDisplayModule()
        let termsConditionsModule = TermsConditionsModule()

        let chatSettingsModule = CompanyChatSettingsModule(entityPickerModule: entityPickerModule,
                                                           qrScannerModule: qrScannerModule,
                                                           qrDisplayModule: qrDisplayModule,
                                                           termsConditionsModule: termsConditionsModule,
                                                           addToChatModule: addToChatModule,
                                                           senderUI: self.externalUI)
        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated

        chatSettingsModule.presentWith(wireframe: wireframe,
                                       chat: chat,
                                       forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    chatSettingsModule.senderUI = externalSenderUI
                }
            }
        }
        return chatSettingsModule
    }

    @objc open func showGroupChatPageFor(chat: Dialog,
                                         animated: Bool,
                                         modally: Bool,
                                         forDelegate delegate: ChatSettingsModuleDelegate?)
                    -> ChatSettingsModuleProtocol {
        let addToChatModule = AddToChatModule()
        let chatSettingsModule = GroupChatSettingsModule(addToChatModule: addToChatModule, senderUI: self.externalUI)

        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated

        chatSettingsModule.presentWith(wireframe: wireframe,
                                       chat: chat,
                                       forDelegate: delegate) {
            if modally && self.externalSenderUI == nil {
                let presentedController = self.rootViewController.presentedViewController
                if let presentedNavigationController = presentedController as? UINavigationController {
                    let externalSenderUI = SenderUI(rootViewController: presentedNavigationController)
                    chatSettingsModule.senderUI = externalSenderUI
                }
            }
        }

        return chatSettingsModule
    }

    @objc open func showQRScreenWith(qrString: String,
                                     delegate: QRScreenModuleDelegate?,
                                     animated: Bool,
                                     modally: Bool) -> QRScreenModuleProtocol? {
        let displayModule = ChildQRDisplayModule()
        let scannerModule = ChildQRServerScannerModule()
        let qrScreenModule = QRScreenModule(qrScannerModule: scannerModule, qrDisplayModule: displayModule)
        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        qrScreenModule.presentWith(wireframe: wireframe,
                                   qrString:qrString,
                                   forDelegate: delegate,
                                   completion: nil)
        return qrScreenModule
    }

    @objc open func showQRScannerWith(delegate: QRScannerModuleDelegate?,
                                      animated: Bool,
                                      modally: Bool) -> QRScannerModule? {
        let scannerModule = ChildQRServerScannerModule()
        let wireframe: ViewControllerWireframe
        if modally {
            wireframe = ModalInNavigationWireframe(rootView: self.rootViewController)
        } else {
            wireframe = PushToNavigationWireframe(rootView: self.rootViewController)
        }
        wireframe.animatedPresentation = animated
        scannerModule.presentWith(wireframe: wireframe, forDelegate: delegate, completion: nil)
        return scannerModule
    }
}
