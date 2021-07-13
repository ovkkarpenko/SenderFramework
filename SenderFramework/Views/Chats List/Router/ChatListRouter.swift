//
// Created by Roman Serga on 14/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class ChatListRouter: ChatListRouterProtocol {

    weak var presenter: ChatListPresenterProtocol?

    var addContactModule: AddContactModuleProtocol
    var qrScannerModule: QRScannerModuleProtocol
    var senderUI: SenderUIProtocol

    fileprivate weak var currentChatListView: ChatListViewController?
    fileprivate var currentWireframe: ViewControllerWireframe?

    init(addContactModule: AddContactModuleProtocol,
         qrScannerModule: QRScannerModuleProtocol,
         senderUI: SenderUIProtocol) {
        self.addContactModule = addContactModule
        self.qrScannerModule = qrScannerModule
        self.senderUI = senderUI
    }

    var chatListView: ChatListViewController {
        if let existingView = self.currentChatListView {
            return existingView
        } else {
            let newView = self.buildChatListView()
            self.currentChatListView = newView
            return newView
        }
    }

    func buildChatListView() -> ChatListViewController {
        return ChatListViewController.loadFromSenderFrameworkStoryboardWith(name: "Main")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: ChatListModuleDelegate?)
                    -> ChatListViewController {
        let chatListView = self.chatListView
        chatListView.presenter = self.presenter
        self.presenter?.view = chatListView
        self.presenter?.delegate = moduleDelegate
        return chatListView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatListModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatListView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatListView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(chatListView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentChatListView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.dismissAddContactForm()
        self.dismissView(completion: completion)
    }

    func showAddContactForm() {
        let addContactWireframe = ModalInNavigationWireframe(rootView: self.chatListView)
        self.addContactModule.presentWith(wireframe: addContactWireframe, forDelegate: self.presenter, completion: nil)
    }

    func dismissAddContactForm() {
        self.addContactModule.dismiss(completion: nil)
    }

    func presentQRScanner() {
        guard let currentView = self.currentChatListView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentView)
        self.qrScannerModule.presentWith(wireframe: wireframe, forDelegate: self.presenter, completion: nil)
    }

    func dismissQRScanner() {
        self.qrScannerModule.dismiss(completion: nil)
    }

    func presentChatWith(chatID: String, actions: [[String: AnyObject]]?) {
        _ = self.senderUI.showChatScreenWith(chatID: chatID,
                                             actions: actions,
                                             options: nil,
                                             animated: true,
                                             modally: false,
                                             delegate: nil)
    }

    func presentChatWith(chat: Dialog, actions: [[String: AnyObject]]?) {
        _ = self.senderUI.showChatScreenWith(chat: chat,
                                             actions: actions,
                                             options: nil,
                                             animated: true,
                                             modally: false,
                                             delegate: nil)
    }

    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol) {
        _ = self.senderUI.showRobotScreenWith(model: callRobotModel,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }
}

class ChildChatListRouter: ChatListRouter, ChildChatListRouterProtocol {

    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: ChatListModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.currentChatListView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatListView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(chatListView, completion: completion)
        self.currentGenericWireframe = AnyWireframeWithAnyRootView(wireframe)
    }

    override func dismissView(completion: (() -> Void)?) {
        super.dismissView(completion: nil)
        guard let currentView = self.currentChatListView else { return }
        self.currentGenericWireframe?.dismissView(currentView, completion: completion)
    }
}
