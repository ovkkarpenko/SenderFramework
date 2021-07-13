//
// Created by Roman Serga on 26/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserProfilePresenter: UserProfilePresenterProtocol {
    weak var view: UserProfileViewProtocol?
    weak var delegate: UserProfileModuleDelegate?
    var router: UserProfileRouterProtocol?
    var interactor: UserProfileInteractorProtocol

    init(interactor: UserProfileInteractorProtocol, router: UserProfileRouterProtocol? = nil) {
        self.router = router
        self.interactor = interactor
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func performMainAction() {
        self.delegate?.userProfileDidPerformedMainAction()
    }

    func showQRScreen() {
        self.interactor.loadQRString()
    }

    func qrScreenModuleDidCancel() {
        self.router?.dismissQRScreen()
    }

    func qrStringWasLoaded(qrString: String) {
        self.router?.presentQRScreenWith(qrString: qrString)
    }

    func showSettings() {
        self.router?.presentSettings()
    }

    func topUpMobile() {
        self.router?.presentTopUpMobileScreen()
    }

    func transferMoney() {
        self.router?.presentTransferMoneyScreen()
    }

    func showWallet() {
        self.router?.presentWalletScreen()
    }

    func showStore() {
        self.router?.presentStoreScreen()
    }

    func createRobot() {
        self.router?.presentCreateRobotScreen()
    }

    func userWasUpdated(_ user: Owner) {
        self.view?.updateWith(user: user)
    }
}
