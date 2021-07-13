//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatListModule: NSObject, ChatListModuleProtocol {

    fileprivate weak var router: ChildChatListRouter?

    @objc public var addContactModule: AddContactModuleProtocol
    @objc public var qrScannerModule: QRScannerModuleProtocol
    @objc public var senderUI: SenderUIProtocol {
        didSet {
            self.router?.senderUI = self.senderUI
        }
    }

    @objc public init(addContactModule: AddContactModuleProtocol,
                      qrScannerModule: QRScannerModuleProtocol,
                      senderUI: SenderUIProtocol) {
        self.addContactModule = addContactModule
        self.qrScannerModule = qrScannerModule
        self.senderUI = senderUI
    }

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: ChatListModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let dataManager = ChatListDataManager()
        let chatListInteractor = ChatListInteractor(dataManager: dataManager)
        let chatListRouter = ChildChatListRouter(addContactModule: self.addContactModule,
                                                 qrScannerModule: self.qrScannerModule,
                                                 senderUI: self.senderUI)
        let chatListPresenter = ChatListPresenter(interactor: chatListInteractor, router: chatListRouter)
        chatListInteractor.presenter = chatListPresenter
        chatListRouter.presenter = chatListPresenter
        chatListRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatListRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    @objc public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }
}

public class ChildChatListModule: ChatListModule, ChildChatListModuleProtocol {

    public func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                              forDelegate delegate: ChatListModuleDelegate?,
                                                              completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let chatListRouter = ChildChatListRouter(addContactModule: self.addContactModule,
                                                 qrScannerModule: self.qrScannerModule,
                                                 senderUI: self.senderUI)
        let dataManager = ChatListDataManager()
        let chatListInteractor = ChatListInteractor(dataManager: dataManager)
        let chatListPresenter = ChatListPresenter(interactor: chatListInteractor, router: chatListRouter)
        chatListInteractor.presenter = chatListPresenter
        chatListRouter.presenter = chatListPresenter
        chatListRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = chatListRouter
    }

}
