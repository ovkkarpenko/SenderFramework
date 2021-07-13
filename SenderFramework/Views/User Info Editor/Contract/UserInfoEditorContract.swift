//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol UserInfoEditorViewProtocol: class {
    var presenter: UserInfoEditorPresenterProtocol? { get set }
    func showInvalidDataError()
    func updateWith(user: Owner)
}

@objc public protocol UserInfoEditorModuleDelegate: class {
    func userInfoEditorModuleDidCancel()
    func userInfoEditorModuleDidFinish()
}

@objc public protocol UserInfoEditorPresenterProtocol: class {
    weak var view: UserInfoEditorViewProtocol? { get set }
    weak var delegate: UserInfoEditorModuleDelegate? { get set }
    var router: UserInfoEditorRouterProtocol? { get set }
    var interactor: UserInfoEditorInteractorProtocol { get set }

    var newName: String { get set }
    var newDescription: String? { get set }
    var newImageData: Data? { get set }

    func viewWasLoaded()
    func userWasUpdated(_ user: Owner)

    func editUser()
    func finishEditingUser()
    func cancelEditingUser()
    func handleError(_ error: Error)

    func loadOriginalUser()
}

@objc public protocol UserInfoEditorRouterProtocol: class {
    weak var presenter: UserInfoEditorPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: UserInfoEditorModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc public protocol UserInfoEditorInteractorProtocol: class {
    weak var presenter: UserInfoEditorPresenterProtocol? { get set }
    var user: Owner! { get }

    func loadData()
    func updateWith(user: Owner)
    func editUserWith(name: String, description: String?, imageData: Data?)
}

protocol UserInfoEditorDataManagerProtocol {
    func edit(user: Owner,
              withName name: String?,
              description: String?,
              imageData: Data?,
              completionHandler: ((Owner?, Error?) -> Void)?) -> Void
    func getOwner() -> Owner
}

@objc public protocol UserInfoEditorModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: UserInfoEditorModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}
