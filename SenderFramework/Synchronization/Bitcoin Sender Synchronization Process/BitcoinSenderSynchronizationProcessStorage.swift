//
// Created by Roman Serga on 6/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc (MWBitcoinSenderSynchronizationProcessStorage)
public class BitcoinSenderSynchronizationProcessStorage: NSObject {

    @objc public func saveMnemonic(_ mnemonic: String,
                                   password: String,
                                   isNewWallet:Bool,
                                   isDefaultWalletPassword: Bool) {
        guard let owner = CoreDataFacade.sharedInstance().getOwner() else {
            fatalError("Cannot get Owner")
        }
        owner.mnemonic = mnemonic

        //TODO: Error handling
        var error: NSError?
        owner.setPassword(password, error: &error, isDefaultWalletPassword: isDefaultWalletPassword)
        owner.walletState = .ready
        owner.authorizationState = .syncedWallet

        if isNewWallet {
            ServerFacade.sharedInstance().sendCurrentWalletToServer()
        }
    }
}
