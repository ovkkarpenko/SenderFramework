//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol BitcoinWalletInfoProtocol {
    var address: String? { get set }
    var bitcoinBalance: String? { get set }
    var dollarBalance: String? { get set }
}

protocol BitcoinSettingsViewProtocol: class {
    var presenter: BitcoinSettingsPresenterProtocol? { get set }
    func updateWith(walletInfo: BitcoinWalletInfoProtocol)

    func showCannotGetWalletError()
    func showCannotGetBalanceError()
}

protocol BitcoinSettingsPresenterProtocol: class, BitcoinConflictResolverDelegate {
    weak var view: BitcoinSettingsViewProtocol? { get set }
    var router: BitcoinSettingsRouterProtocol? { get set }
    var interactor: BitcoinSettingsInteractorProtocol { get set }

    func viewWasLoaded()
    func updateData()
    func walletAddressWasUpdated(walletAddress: String)
    func walletBalanceWasUpdated(bitcoinBalance: String?, usdBalance: String?)

    func handleCannotGetWalletError()
    func handleCannotGetBalanceError()

    func resolveWalletsConflict()
}

protocol BitcoinSettingsRouterProtocol: class {
    weak var presenter: BitcoinSettingsPresenterProtocol? { get set }

    func presentViewWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func presentConflictResolvingScreen()
}

protocol BitcoinSettingsInteractorProtocol: class {
    weak var presenter: BitcoinSettingsPresenterProtocol? { get set }

    func loadData()
    func conflictWasResolved()
}

protocol BitcoinSettingsDataManagerProtocol: class {
    func getBitcoinWallet(completion: ((BitcoinWallet?, BitcoinWalletState, Error?) -> Void)?)
    func getUnspentTransactionsFor(wallet: BitcoinWallet, completion: (([BTCTransactionOutput]?, Error?) -> Void)?)
    func getBitcoinExchangeRate(completion: ((Double?, Error?) -> Void)?)

}

@objc public protocol BitcoinSettingsModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}
