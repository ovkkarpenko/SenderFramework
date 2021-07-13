//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class BlockedUsersModule: NSObject, BlockedUsersModuleProtocol {

    private weak var router: EntityPickerRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            forDelegate delegate: EntityPickerModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatEditManager = ChatEditManager(input: chatEditManagerInput)
        let blockedUsersDataManager = BlockedUsersDataManager(chatEditManager: chatEditManager)
        let entityPickerInteractor = BlockedUsersInteractor(dataManager: blockedUsersDataManager)
        let entityPickerRouter = BlockedUsersRouter()
        let entityPickerPresenter = EntityPickerPresenter(interactor: entityPickerInteractor,
                                                          router: entityPickerRouter)
        entityPickerInteractor.presenter = entityPickerPresenter
        entityPickerRouter.presenter = entityPickerPresenter
        entityPickerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = entityPickerRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
