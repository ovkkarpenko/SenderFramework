//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BitcoinSettingsPresenter: BitcoinSettingsPresenterProtocol {

    weak var view: BitcoinSettingsViewProtocol?
    var router: BitcoinSettingsRouterProtocol?
    var interactor: BitcoinSettingsInteractorProtocol

    var walletInfo = BitcoinWalletInfo()

    init(interactor: BitcoinSettingsInteractorProtocol, router: BitcoinSettingsRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func updateData() {
        self.interactor.loadData()
    }

    func walletAddressWasUpdated(walletAddress: String) {
        self.walletInfo.address = walletAddress
        self.view?.updateWith(walletInfo: self.walletInfo)
    }

    func walletBalanceWasUpdated(bitcoinBalance: String?, usdBalance: String?) {
        self.walletInfo.bitcoinBalance = bitcoinBalance
        self.walletInfo.dollarBalance = usdBalance
        self.view?.updateWith(walletInfo: self.walletInfo)
    }

    func handleCannotGetWalletError() {
        self.view?.showCannotGetWalletError()
    }

    func handleCannotGetBalanceError() {
        self.view?.showCannotGetBalanceError()
    }

    func resolveWalletsConflict() {
        self.router?.presentConflictResolvingScreen()
    }

    @objc func bitcoinConflictResolverDidFinished(_ conflictResolver: BitcoinConflictResolver) {
        self.interactor.conflictWasResolved()
    }
}
