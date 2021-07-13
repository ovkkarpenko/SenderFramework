//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class UserInfoEditorModule: NSObject, UserInfoEditorModuleProtocol {

    private weak var router: UserInfoEditorRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            forDelegate delegate: UserInfoEditorModuleDelegate?,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }

        let userInfoEditorDataManager = UserInfoEditorDataManager()
        let userInfoEditorInteractor = UserInfoEditorInteractor(dataManager: userInfoEditorDataManager)
        let userInfoEditorRouter = UserInfoEditorRouter()
        let userInfoEditorPresenter = UserInfoEditorPresenter(interactor: userInfoEditorInteractor,
                                                              router: userInfoEditorRouter)
        userInfoEditorInteractor.presenter = userInfoEditorPresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(userInfoEditorInteractor)
        userInfoEditorRouter.presenter = userInfoEditorPresenter
        userInfoEditorRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = userInfoEditorRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

}
