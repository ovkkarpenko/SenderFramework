//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BitcoinSettingsDataManager: BitcoinSettingsDataManagerProtocol {

    func getBitcoinWallet(completion: ((BitcoinWallet?, BitcoinWalletState, Error?) -> Void)?) {
        do {
            let currentWallet = try CoreDataFacade.sharedInstance().getOwner().getMainWallet()
            let walletState = CoreDataFacade.sharedInstance().getOwner().walletState
            completion?(currentWallet, walletState, nil)
        } catch let error {
            completion?(nil, .unknown, error)
        }
    }

    func getUnspentTransactionsFor(wallet: BitcoinWallet,
                                   completion: (([BTCTransactionOutput]?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().getUnspentTransactions(for: wallet) { transactions, error in
            guard let transactions = transactions as? [BTCTransactionOutput], error == nil else {
                let returnError = error ?? NSError(domain: "Cannot get unspent transactions", code: 666)
                completion?(nil, returnError)
                return
            }
            completion?(transactions, nil)
        }
    }

    func getBitcoinExchangeRate(completion: ((Double?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().getBitcoinMarketPrice { response, error -> Void in
            guard let pricesDict = response as? [String: [String: AnyObject]],
                  let usdPrices = pricesDict["USD"],
                  let bitcoinMarketPrice = usdPrices["last"] as? Double else {
                let returnError = error ?? NSError(domain: "Cannot get bitcoin exchange rate", code: 666)
                completion?(nil, returnError)
                return
            }
            completion?(bitcoinMarketPrice, nil)
        }
    }
}
