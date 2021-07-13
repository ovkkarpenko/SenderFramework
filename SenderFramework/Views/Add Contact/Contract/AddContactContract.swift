//
// Created by Roman Serga on 28/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol AddContactViewProtocol: class {
    var presenter: AddContactPresenterProtocol? { get set }
    func showInvalidDataError()
}

@objc public protocol AddContactModuleDelegate: class {
    func addContactPresenterDidCancel()
    func addContactPresenterDidFinish()
}

@objc public protocol AddContactPresenterProtocol: class {
    weak var view: AddContactViewProtocol? { get set }
    weak var delegate: AddContactModuleDelegate? { get set }
    var router: AddContactRouterProtocol? { get set }
    var interactor: AddContactInteractorProtocol { get set }

    func addContactWith(name: String, phone: String)
    func finishAddingContact()
    func cancelAddingContact()
    func handleError(_ error: Error)
}

@objc public protocol AddContactRouterProtocol: class {
    weak var presenter: AddContactPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: AddContactModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc public protocol AddContactInteractorProtocol: class {
    weak var presenter: AddContactPresenterProtocol? { get set }
    func addContactWith(name: String, phone: String)
}

protocol AddContactDataManagerProtocol {
    func addContactWith(name: String, phone: String, completion: @escaping (([AnyHashable: Any]?, Error?) -> Void))
}

@objc public protocol AddContactModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: AddContactModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}