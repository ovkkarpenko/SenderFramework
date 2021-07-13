//
//  BitcoinConflictResolver.swift
//  SENDER
//
//  Created by Roman Serga on 16/3/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

@objc public protocol BitcoinConflictResolverDelegate {
    @objc func bitcoinConflictResolverDidFinished(_ conflictResolver: BitcoinConflictResolver)
}

@objc open class BitcoinConflictResolver: NSObject, BitcoinSyncManagerDelegate, BitcoinSyncManagerDataSource {

    @objc public static let shared = BitcoinConflictResolver()

    var syncManager: BitcoinSyncManager!
    var remoteMnemonic: String?
    var remoteWallet: BitcoinWallet!
    weak var delegate: BitcoinConflictResolverDelegate?
    var hasShownFirstScreen = false
    var hasPassedFirstStep = false

    @objc public func startConflictResolvingIn(rootViewController: UIViewController,
                                         delegate: BitcoinConflictResolverDelegate? = nil) {
        guard let bitcoinSyncManagerBuilder = SenderCore.shared().bitcoinSyncManagerBuilder else {
            fatalError("bitcoinSyncManagerBuilder is nil. " +
                               "Shared SenderCore must have non-nil bitcoinSyncManagerBuilder")
        }

        self.delegate = delegate
        self.syncManager = bitcoinSyncManagerBuilder.syncManager(withRootViewController: rootViewController,
                                                                 delegate: self)
        self.syncManager.dataSource = self
        self.startConflictResolving()
    }
    @objc open func startConflictResolving () {
        ServerFacade.sharedInstance().getStorageValue { response, _ -> Void in
            DispatchQueue.main.async {
                if let mnemonic = response?["storage"] as? String {
                    self.remoteMnemonic = mnemonic
                    if self.hasPassedFirstStep || !self.hasShownFirstScreen {
                        self.syncManager.startCurrentPasswordCheckingForConflict()
                        self.hasPassedFirstStep = false
                        self.hasShownFirstScreen = true
                    }
                } else {
                }
            }
        }
    }

    func checkForConflict() {
        do {
            let password = try CoreDataFacade.sharedInstance().getOwner().getPassword()
            self.remoteWallet = BitcoinWallet(encryptedMnemonic:self.remoteMnemonic,
                                              password: password,
                                              acceptDefaultWalletMnemonic:true)

            //Password wasn't changed. User needs to choose one of two wallets
            if self.remoteWallet.mnemonic != nil {
                if try CoreDataFacade.sharedInstance().getOwner().getMainWallet() != self.remoteWallet {
                    let localMnemonic = try CoreDataFacade.sharedInstance().getOwner().getMainWallet().mnemonic
                    self.syncManager.startWalletChoosingForConflict(self.remoteWallet.mnemonic,
                                                                    localMnemonic: localMnemonic!)
                } else {
                    self.finishResolvingConflict()
                }
            }
            //Password was changed. We need to ask for a new password and then
            //either set it as local password (if wallet wasn't changed) either
            //prompt user to choose one of two wallets
            else {
                self.syncManager.startRemotePasswordChecking()
            }
        } catch {
        }
    }

    fileprivate func finishResolvingConflict () {
        remoteWallet = nil
        CoreDataFacade.sharedInstance().getOwner().walletState = .ready
        self.delegate?.bitcoinConflictResolverDidFinished(self)
    }

    //MARK : BitcoinSyncManager Delegate and DataSource

    open func bitcoinSyncManagerDidFinishedImportWithMnemonic(_ mnemonic: BTCMnemonic?, andError error: NSError?) {
        let wallet = BitcoinWallet(mnemonic: mnemonic)
        var error: NSError?
        CoreDataFacade.sharedInstance().getOwner().setMainWallet(wallet, error: &error, asDefaultWallet: false)

        guard error == nil else { return }
        ServerFacade.sharedInstance().sendCurrentWalletToServer()
        finishResolvingConflict()
    }

    open func bitcoinSyncManagerDidFinishedCreatingPassword(_ password: String) {
        var error: NSError?
        let testWallet = BitcoinWallet(encryptedMnemonic: self.remoteMnemonic,
                                       password: password,
                                       acceptDefaultWalletMnemonic: true)

        CoreDataFacade.sharedInstance().getOwner().setPassword(password, error: &error, isDefaultWalletPassword: false)
        if error == nil {
            guard testWallet?.mnemonic != nil else {
                CoreDataFacade.sharedInstance().getOwner().setRandomMainWallet(nil, asDefaultWallet: false)
                ServerFacade.sharedInstance().sendCurrentWalletToServer()
                return
            }
            if remoteWallet == nil {
                ServerFacade.sharedInstance().sendCurrentWalletToServer()
            }
        }
        checkForConflict()
    }

    open func bitcoinSyncManagerDidFinishedCheckingPassword(_ isRightPassword: Bool) {
        if isRightPassword {
            checkForConflict()
            hasPassedFirstStep = true
        } else {
            self.syncManager.startCurrentPasswordCheckingForConflict()
        }
    }

    open func bitcoinSyncManagerIsRemotePasswordRight(_ password: String) -> Bool {
        let checkWallet = BitcoinWallet(encryptedMnemonic:self.remoteMnemonic,
                                        password: password,
                                        acceptDefaultWalletMnemonic: true)
        return checkWallet!.mnemonic != nil
    }

    open func bitcoinSyncManagerPasswordToCheck(_ syncManager: BitcoinSyncManager) -> String {
        return try! CoreDataFacade.sharedInstance().getOwner().getPassword()
    }

    open func bitcoinSyncManagerWasCanceled() {
        self.delegate?.bitcoinConflictResolverDidFinished(self)
    }
}
