//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatRouter: ChatRouterProtocol {

    weak var presenter: ChatPresenterProtocol?

    var addToChatModule: AddToChatModuleProtocol
    var qrScannerModule: QRScannerModuleProtocol
    var qrDisplayModule: QRDisplayModule
    var fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol
    var senderUI: SenderUIProtocol

    var currentChatSettingsModule: ChatSettingsModuleProtocol?

    init(addToChatModule: AddToChatModuleProtocol,
         qrScannerModule: QRScannerModuleProtocol,
         qrDisplayModule: QRDisplayModule,
         fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol,
         senderUI: SenderUIProtocol) {
        self.addToChatModule = addToChatModule
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
        self.fmlActionsHandlerRouter = fmlActionsHandlerRouter
        self.senderUI = senderUI
    }

    private var currentWireframe: ViewControllerWireframe?
    private weak var currentChatView: ChatViewController?

    var chatView: ChatViewController {
        if let existingView = self.currentChatView {
            return existingView
        } else {
            let newView = self.buildChatView()
            self.currentChatView = newView
            return newView
        }
    }

    func buildChatView() -> ChatViewController {
        return ChatViewController()
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatModuleDelegate?,
                                                          model: ChatPresentationModelProtocol)
                    -> ChatViewController {
        let chatView = self.chatView
        chatView.presenter = self.presenter
        chatView.fmlActionsHandlerView.presenter = self.presenter?.fmlActionsHandlerPresenter
        self.presenter?.view = chatView
        self.presenter?.fmlActionsHandlerPresenter.view = chatView.fmlActionsHandlerView
        self.presenter?.delegate = moduleDelegate
        return chatView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         model: ChatPresentationModelProtocol,
                         forDelegate delegate: ChatModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate, model: model)
        wireframe.presentView(chatView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentChatView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.currentChatSettingsModule?.dismissWithChildModules(completion: nil)
        self.dismissAddMemberScreen()
        self.dismissQRScanner()
        self.fmlActionsHandlerRouter.dismissAllViews(completion: nil)
        self.dismissView(completion: completion)
    }

    func showChatSettingsWith(chat: Dialog) {
        switch chat.chatType {
        case .P2P:
            self.currentChatSettingsModule = self.senderUI.showContactPageFor(chat: chat,
                                                                              animated: true,
                                                                              modally: false,
                                                                              forDelegate: self.presenter)
        case .group:
            self.currentChatSettingsModule = self.senderUI.showGroupChatPageFor(chat: chat,
                                                                                animated: true,
                                                                                modally: false,
                                                                                forDelegate: self.presenter)
        case .company:
            self.currentChatSettingsModule = self.senderUI.showCompanyPageFor(chat: chat,
                                                                              animated: true,
                                                                              modally: false,
                                                                              forDelegate: self.presenter)
        default: break
        }
    }

    func dismissChatSettings() {
        self.currentChatSettingsModule?.dismissWithChildModules(completion: nil)
        self.currentChatSettingsModule = nil
    }

    func showCallScreen() {
    }

    func presentAddMemberScreen() {
        guard let currentChatView = currentChatView, let chat = self.presenter?.interactor.chat else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        self.addToChatModule.presentWith(wireframe: wireframe,
                                         chat: chat,
                                         allowsMultipleSelection: true,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissAddMemberScreen() {
        self.addToChatModule.dismiss(completion: nil)
    }

    func presentQRScanner() {
        guard let currentChatView = currentChatView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        wireframe.animatedPresentation = true
        self.qrScannerModule.presentWith(wireframe: wireframe,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissQRScanner() {
        self.qrScannerModule.dismiss(completion: nil)
    }

    func presentQRCodeWith(string: String) {
        guard let currentChatView = currentChatView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        wireframe.animatedPresentation = true
        self.qrDisplayModule.presentWith(wireframe: wireframe,
                                         qrString: string,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissQRCode() {
        self.qrDisplayModule.dismiss(completion: nil)
    }

    func openChatScreenWith(chat: Dialog) {
        self.senderUI.showChatScreenWith(chat: chat,
                                         actions: nil,
                                         options: nil,
                                         animated: true,
                                         modally: false,
                                         delegate: nil)
    }
}

extension ChatRouter: FMLActionsHandlerRouterDelegate {
    func fmlActionsHandlerRouterViewControllerForPresentation(_ fmlActionsHandlerRouter: FMLActionsHandlerRouter)
                    -> UIViewController? {
        return self.currentChatView
    }
}
