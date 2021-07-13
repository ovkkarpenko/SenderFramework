//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class AddToChatModule: NSObject, AddToChatModuleProtocol {

    private weak var router: EntityPickerRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            chat: Dialog,
                            allowsMultipleSelection: Bool,
                            forDelegate delegate: AddToChatModuleDelegate?,
                            completion: (() -> Void)?) {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatEditManager = ChatEditManager(input: chatEditManagerInput)
        let addToChatDataManager = AddToChatDataManager(chatEditManager: chatEditManager)
        let addToChatInteractor = AddToChatInteractor(dataManager: addToChatDataManager)
        let addToChatRouter = AddToChatRouter()
        let addToChatPresenter = AddToChatPresenter(interactor: addToChatInteractor, router: addToChatRouter)
        addToChatInteractor.updateWith(chat: chat)
        addToChatInteractor.addToChatPresenter = addToChatPresenter
        addToChatRouter.addToChatPresenter = addToChatPresenter
        addToChatRouter.presentAddToChatViewWith(wireframe: wireframe,
                                                 forDelegate: delegate,
                                                 completion: completion)
        self.router = addToChatRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

}
