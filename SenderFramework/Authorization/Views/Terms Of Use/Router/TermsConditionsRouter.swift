//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class TermsConditionsRouter: TermsConditionsRouterProtocol {

    weak var presenter: TermsConditionsPresenterProtocol?

    private weak var currentTermsConditionsView: TermsConditionsViewController?
    private var currentWireframe: ViewControllerWireframe?

    var termsConditionsView: TermsConditionsViewController {
        if let existingView = self.currentTermsConditionsView {
            return existingView
        } else {
            let newView = self.buildTermsConditionsView()
            self.currentTermsConditionsView = newView
            return newView
        }
    }

    func buildTermsConditionsView() -> TermsConditionsViewController {
        return TermsConditionsViewController.loadFromSenderFrameworkStoryboardWith(name: "Registration")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: TermsConditionsModuleDelegate?)
                    -> TermsConditionsViewController {
        let termsConditionsView = self.termsConditionsView
        termsConditionsView.presenter = self.presenter
        self.presenter?.view = termsConditionsView
        self.presenter?.delegate = moduleDelegate
        return termsConditionsView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: TermsConditionsModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentTermsConditionsView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let termsConditionsView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(termsConditionsView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let termsConditionsView = self.currentTermsConditionsView else { return }
        self.currentWireframe?.dismissView(termsConditionsView, completion: completion)
    }

}
