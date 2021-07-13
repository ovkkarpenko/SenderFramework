//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public class MainScreenModule: NSObject, MainScreenModuleProtocol {

    var chatListModule: ChildChatListModuleProtocol
    var userProfileModule: ChildUserProfileModuleProtocol

    fileprivate weak var router: MainScreenRouterProtocol?

    public init(chatListModule: ChildChatListModuleProtocol,
                userProfileModule: ChildUserProfileModuleProtocol) {
        self.chatListModule = chatListModule
        self.userProfileModule = userProfileModule
    }

    public func presentWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?) {
        typealias RouterType = MainScreenRouter
        typealias PresenterType = MainScreenPresenter

        let mainScreenRouter = MainScreenRouter(chatListModule: self.chatListModule,
                                                userProfileModule: self.userProfileModule)
        let mainScreenPresenter = MainScreenPresenter(router: mainScreenRouter)
        mainScreenRouter.presenter = mainScreenPresenter
        mainScreenRouter.presentViewWith(wireframe: wireframe, completion: completion)
        self.router = mainScreenRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
