//
// Created by Roman Serga on 28/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddContactRouter: AddContactRouterProtocol {

    weak var presenter: AddContactPresenterProtocol?

    private weak var currentAddContactView: AddContactViewController?
    private var currentWireframe: ViewControllerWireframe?

    var addContactView: AddContactViewController {
        if let existingView = self.currentAddContactView {
            return existingView
        } else {
            let newView = self.buildAddContactView()
            self.currentAddContactView = newView
            return newView
        }
    }

    func buildAddContactView() -> AddContactViewController {
        return AddContactViewController.loadFromSenderFrameworkStoryboardWith(name: "ContactViews")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: AddContactModuleDelegate?)
                    -> AddContactViewController {
        let addContactView = self.addContactView
        self.presenter?.delegate = moduleDelegate
        self.presenter?.view = addContactView
        addContactView.presenter = presenter
        return addContactView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: AddContactModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentAddContactView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let addContactView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(addContactView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentAddContactView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }
}
