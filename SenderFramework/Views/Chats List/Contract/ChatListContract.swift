//
// Created by Roman Serga on 14/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ChatListViewProtocol: class {
    var presenter: ChatListPresenterProtocol? { get set }

    func setSyncIndicatorVisible(_ syncIndicatorVisible: Bool)
}

@objc public protocol ChatListModuleDelegate: class {
    func chatListDidPerformedMainAction()
}

@objc public protocol ChatListPresenterProtocol: class, AddContactModuleDelegate, QRScannerModuleDelegate {
    weak var view: ChatListViewProtocol? { get set }
    weak var delegate: ChatListModuleDelegate? { get set }
    var router: ChatListRouterProtocol? { get set }
    var interactor: ChatListInteractorProtocol { get set }

    func viewWasLoaded()

    func performMainAction()
    func startAddingContact()
    func showQRScanner()

    func showChatWith(chatID: String, actions: [[String: AnyObject]]?)
    func showChatWith(chat: Dialog, actions: [[String: AnyObject]]?)
    func launchAction(_ action: ActionCellModel)

    func handleIsSyncingState(_ isSyncing: Bool)
}

@objc public protocol ChatListRouterProtocol: class {
    weak var presenter: ChatListPresenterProtocol? { get set }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatListModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func showAddContactForm()
    func dismissAddContactForm()

    func presentQRScanner()
    func dismissQRScanner()

    func presentChatWith(chatID: String, actions: [[String: AnyObject]]?)
    func presentChatWith(chat: Dialog, actions: [[String: AnyObject]]?)
    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol)
}

@objc public protocol ChatListInteractorProtocol {
    weak var presenter: ChatListPresenterProtocol? { get set }
    func loadData()
}

public protocol SenderCoreInSyncingObserver: class {
    func senderCore(_ senderCore: SenderCore, isSyncingDidChange isSyncing: Bool)
}

public protocol ChatListDataManagerProtocol {
    func startObservingIsSyncingChangesWith(observer: SenderCoreInSyncingObserver)
    func stopObservingIsSyncingChanges()
}

public protocol ChildChatListRouterProtocol: ChatListRouterProtocol {
    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: ChatListModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}

@objc public protocol ChatListModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: ChatListModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}

public protocol ChildChatListModuleProtocol: ChatListModuleProtocol {
    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       forDelegate delegate: ChatListModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}
