//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BitcoinSettingsInteractor: BitcoinSettingsInteractorProtocol {
    weak var presenter: BitcoinSettingsPresenterProtocol?

    var dataManager: BitcoinSettingsDataManagerProtocol
    var bitcoinWallet: BitcoinWallet!

    init(dataManager: BitcoinSettingsDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        self.dataManager.getBitcoinWallet { bitcoinWallet, walletState, error in
            guard let bitcoinWallet = bitcoinWallet, error == nil else {
                self.presenter?.handleCannotGetWalletError()
                return
            }

            self.bitcoinWallet = bitcoinWallet

            guard walletState != .needSync else {
                self.presenter?.resolveWalletsConflict()
                return
            }

            let walletAddress = self.bitcoinWallet.paymentKey.compressedPublicKeyAddress.string
            self.presenter?.walletAddressWasUpdated(walletAddress: walletAddress)
            self.presenter?.walletBalanceWasUpdated(bitcoinBalance: nil, usdBalance: nil)

            self.getWalletBalance()
        }
    }

    func getWalletBalance() {
        self.dataManager.getUnspentTransactionsFor(wallet: self.bitcoinWallet) { outputs, error in
            guard let unspentOutputs = outputs, error == nil else {
                DispatchQueue.main.async { self.presenter?.handleCannotGetBalanceError() }
                return
            }

            self.bitcoinWallet.unspentOutputs = unspentOutputs

            guard let walletBalance = self.bitcoinWallet.balance else {
                DispatchQueue.main.async { self.presenter?.walletBalanceWasUpdated(bitcoinBalance: nil,
                                                                                   usdBalance: nil) }
                return
            }

            self.dataManager.getBitcoinExchangeRate { dollarPrice, error in
                DispatchQueue.main.async {
                    guard let dollarPrice = dollarPrice, error == nil else {
                        self.presenter?.walletBalanceWasUpdated(bitcoinBalance: walletBalance, usdBalance: nil)
                        return
                    }

                    let dollarPriceNumber = NSDecimalNumber(floatLiteral: dollarPrice)
                    let balanceNumber = NSDecimalNumber(string: walletBalance)
                    let numberHandler = NSDecimalNumberHandler(roundingMode: .down,
                                                               scale: 2,
                                                               raiseOnExactness: false,
                                                               raiseOnOverflow: false,
                                                               raiseOnUnderflow: false,
                                                               raiseOnDivideByZero: false)
                    let dollarBalance = balanceNumber.multiplying(by: dollarPriceNumber)
                    let result = dollarBalance.rounding(accordingToBehavior: numberHandler).description(withLocale: nil)
                    self.presenter?.walletBalanceWasUpdated(bitcoinBalance: walletBalance, usdBalance: result)
                }
            }
        }
    }

    func conflictWasResolved() {
        self.loadData()
    }

}
