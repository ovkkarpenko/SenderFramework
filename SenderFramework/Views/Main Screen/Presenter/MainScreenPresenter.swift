//
// Created by Roman Serga on 18/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class MainScreenPresenter: MainScreenPresenterProtocol {

    weak var view: MainScreenViewProtocol?
    var router: MainScreenRouterProtocol?

    init(router: MainScreenRouterProtocol) {
        self.router = router
    }

    func viewWasLoaded() {
        self.router?.presentChildViews()
    }

    func showChatList() {
        self.router?.showChatList()
    }

    func showUserProfile() {
        self.router?.showUserProfile()
    }

    func chatListDidPerformedMainAction() {
        self.showUserProfile()
    }

    func userProfileDidPerformedMainAction() {
        self.showChatList()
    }

}
