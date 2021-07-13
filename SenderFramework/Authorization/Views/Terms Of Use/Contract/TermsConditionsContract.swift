//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol TermsConditionsViewProtocol: class {
    var presenter: TermsConditionsPresenterProtocol? { get set }
    func textWasUpdated(text: NSAttributedString)
}

@objc public protocol TermsConditionsModuleDelegate: class {
    func termsConditionsModuleDidAccept()
    func termsConditionsModuleDidDecline()
}

@objc public protocol TermsConditionsPresenterProtocol: class {
    weak var view: TermsConditionsViewProtocol? { get set }
    weak var delegate: TermsConditionsModuleDelegate? { get set }
    var router: TermsConditionsRouterProtocol? { get set }
    var interactor: TermsConditionsInteractorProtocol { get set }

    func viewWasLoaded()
    func termsConditionsTextWasUpdated(text: NSAttributedString)

    func accept()
    func decline()
}

@objc public protocol TermsConditionsRouterProtocol: class {
    weak var presenter: TermsConditionsPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: TermsConditionsModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc public protocol TermsConditionsInteractorProtocol: class {
    weak var presenter: TermsConditionsPresenterProtocol? { get set }

    func loadData()
}

@objc public protocol TermsConditionsDataManagerProtocol {
    func getFileURL() -> URL?
}

@objc public protocol TermsConditionsModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: TermsConditionsModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}
