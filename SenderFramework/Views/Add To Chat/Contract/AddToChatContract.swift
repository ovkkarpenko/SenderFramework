//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol AddToChatViewProtocol: EntityPickerViewProtocol {
    func showOnlyOneCompanyError()
    func showCannotAddToChatError()
}

@objc public protocol AddToChatModuleDelegate: EntityPickerModuleDelegate {
    func addToChatModuleDidFinishWith(newChat: Dialog, selectedEntities: [EntityViewModel])
}

@objc public protocol AddToChatPresenterProtocol: EntityPickerPresenterProtocol {
    weak var addToChatDelegate: AddToChatModuleDelegate? { get set }
    weak var addToChatView: AddToChatViewProtocol? { get set }
    func handleOnlyOneCompanyError()
    func handleAddingToChatError()

    func finishAddingToChatWith(newChat: Dialog, selectedEntities: [EntityViewModel])
}

@objc public protocol AddToChatRouterProtocol: EntityPickerRouterProtocol {
    weak var addToChatPresenter: AddToChatPresenterProtocol? { get set }
    func presentAddToChatViewWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: AddToChatModuleDelegate?,
                                  completion: (() -> Void)?)
}

@objc public protocol AddToChatInteractorProtocol {
    var chat: Dialog! { get }
    weak var addToChatPresenter: AddToChatPresenterProtocol? { get set }

    func updateWith(chat: Dialog)
}

@objc public protocol AddToChatDataManagerProtocol {
    func add(members: [Dialog],
             toChat chat: Dialog,
             completionHandler: ((Dialog?, Error?) -> Void)?)

    func loadEntities(completion: (([Dialog]) -> Void)?)
}

@objc public protocol AddToChatModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     chat: Dialog,
                     allowsMultipleSelection: Bool,
                     forDelegate delegate: AddToChatModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}