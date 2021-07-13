//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class AddContactModule: NSObject, AddContactModuleProtocol {
    fileprivate weak var router: AddContactRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            forDelegate delegate: AddContactModuleDelegate?,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let addContactDataManager = AddContactDataManager()
        let addContactInteractor = AddContactInteractor(dataManager: addContactDataManager)
        let addContactRouter = AddContactRouter()
        let addContactPresenter = AddContactPresenter(interactor: addContactInteractor, router: addContactRouter)
        addContactInteractor.presenter = addContactPresenter
        addContactRouter.presenter = addContactPresenter
        addContactRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = addContactRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
