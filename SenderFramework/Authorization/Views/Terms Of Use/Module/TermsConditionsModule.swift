//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class TermsConditionsModule: NSObject, TermsConditionsModuleProtocol {

    private weak var router: TermsConditionsRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: TermsConditionsModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }

        let termsConditionsDataManager = TermsConditionsDataManager()
        let termsConditionsInteractor = TermsConditionsInteractor(dataManager: termsConditionsDataManager)
        let termsConditionsRouter = TermsConditionsRouter()
        let termsConditionsPresenter = TermsConditionsPresenter(interactor: termsConditionsInteractor,
                                                              router: termsConditionsRouter)
        termsConditionsInteractor.presenter = termsConditionsPresenter
        termsConditionsRouter.presenter = termsConditionsPresenter
        termsConditionsRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = termsConditionsRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
