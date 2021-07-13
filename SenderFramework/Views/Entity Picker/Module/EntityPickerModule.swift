//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class EntityPickerModule: NSObject, EntityPickerModuleProtocol {

    private weak var router: EntityPickerRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            entityModels: [EntityViewModel],
                            allowsMultipleSelection: Bool,
                            forDelegate delegate: EntityPickerModuleDelegate?,
                            completion: (() -> Void)?) {
        let entityPickerInteractor = EntityPickerInteractor(allowsMultipleSelection: allowsMultipleSelection)
        let entityPickerRouter = EntityPickerRouter()
        let entityPickerPresenter = EntityPickerPresenter(interactor: entityPickerInteractor,
                                                          router: entityPickerRouter)
        entityPickerInteractor.updateWith(entities: entityModels)
        entityPickerInteractor.presenter = entityPickerPresenter
        entityPickerRouter.presenter = entityPickerPresenter
        entityPickerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = entityPickerRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

}
