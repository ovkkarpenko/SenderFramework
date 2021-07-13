//
// Created by Roman Serga on 6/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public extension SynchronizationProcessState {
    @objc static let syncingBitcoin = SynchronizationProcessState(name: "syncingBitcoin")
}

//@objc(MWSenderSynchronizationProcessStorageProtocol)
@objc public protocol BitcoinSenderSynchronizationProcessStorageProtocol {
    func saveMnemonic(_ mnemonic: String, password: String, isNewWallet:Bool, isDefaultWalletPassword: Bool)
}

@objc(MWBitcoinSenderSynchronizationDefaultWalletLogicProtocol)
public protocol BitcoinSenderSynchronizationDefaultWalletLogicProtocol {
    @objc optional func passwordActionFor(mnemonic: String?) -> SenderAuthBitcoinPasswordAction
    @objc optional func defaultWalletPasswordFor(synchronizationProcess: BitcoinSenderSynchronizationProcess) -> String
}

//TODO: Refactor after refactoring whole bitcoin module
@objc(MWBitcoinSenderSynchronizationProcess)
public class BitcoinSenderSynchronizationProcess: SenderSynchronizationProcess, BitcoinSyncManagerDelegate {

    @objc public var bitcoinSyncManager: BitcoinSyncManager
    @objc public var bitcoinStorage: BitcoinSenderSynchronizationProcessStorageProtocol
    @objc public var defaultWalletLogic: BitcoinSenderSynchronizationDefaultWalletLogicProtocol?

    private var bitcoinSyncCompletion: ((Error?) -> Void)?
    private var mnemonic: String?

    @objc public init(bitcoinSyncManager: BitcoinSyncManager,
                      bitcoinStorage: BitcoinSenderSynchronizationProcessStorageProtocol,
                      synchronizationManager: SynchronizationManagerProtocol,
                      storage: SenderSynchronizationProcessStorage) {
        self.bitcoinSyncManager = bitcoinSyncManager
        self.bitcoinStorage = bitcoinStorage
        super.init(synchronizationManager: synchronizationManager, storage: storage)
        self.bitcoinSyncManager.delegate = self
    }

    @objc open override func nextStateAfter(state: SynchronizationProcessState) throws -> SynchronizationProcessState {
        if state == .none {
            return .syncingBitcoin
        } else if state == .syncingBitcoin {
            let originalFirstState = try super.nextStateAfter(state: .none)
            return originalFirstState
        } else {
            return try super.nextStateAfter(state: state)
        }
    }

    @objc open override func performActionFor(state: SynchronizationProcessState,
                                              completion: @escaping ((Error?) -> Void)) {
        if state == .syncingBitcoin {
            self.syncBitcoinWith(completion: completion)
        } else {
            super.performActionFor(state: state, completion: completion)
        }
    }

    @objc public func syncBitcoinWith(completion: @escaping (Error?) -> Void) {
        self.bitcoinSyncCompletion = completion
        self.runPasswordController()
    }

    func loadBitcoinData(withCompletion completionHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().updateSelfInfo({(_ response: [AnyHashable: Any]?, _ error: Error?) -> Void in
            ServerFacade.sharedInstance().getStorageValue(completionHandler: completionHandler)
        })
    }

    func runPasswordController() {
        self.loadBitcoinData { response, error in
            let remoteMnemonic = (response?["storage"] as? String) ?? ""
            let passwordAction: SenderAuthBitcoinPasswordAction

            if let externalPasswordAction = self.defaultWalletLogic?.passwordActionFor?(mnemonic: remoteMnemonic),
               externalPasswordAction != .undefined {
                passwordAction = externalPasswordAction
            } else {
                passwordAction = (remoteMnemonic.characters.count > 0) ? .saveCurrent : .createNew
            }

            switch passwordAction {
            case .createNew:
                self.bitcoinSyncManager.startPasswordCreation()
            case .createDefault:
                self.createNewDefaultWallet()
            case .saveCurrent:
                self.mnemonic = remoteMnemonic
                self.bitcoinSyncManager.startPasswordImport()
            case .saveCurrentAndSetDefaultPassword:
                self.mnemonic = remoteMnemonic
                let defaultPassword = self.defaultWalletLogic?.defaultWalletPasswordFor?(synchronizationProcess: self)
                if let password = defaultPassword {
                    self.savePassword(password, isDefaultPassword: true)
                } else {
                    self.bitcoinSyncManager.startPasswordImport()
                }
            case .undefined:
                break
            }
        }
    }

    public func bitcoinSyncManagerDidFinishedCreatingPassword(_ password: String) {
        self.savePassword(password, isDefaultPassword: false)
    }

    public func bitcoinSyncManagerIsPasswordRight(_ password: String) -> Bool {
        let ownerMnemonic = self.mnemonic!
        let testWallet = BitcoinWallet(encryptedMnemonic: ownerMnemonic,
                                       password: password,
                                       acceptDefaultWalletMnemonic: true)
        return testWallet?.mnemonic != nil
    }

    func savePassword(_ password: String, isDefaultPassword: Bool) {
        var wallet: BitcoinWallet?
        if let ownerMnemonic: String = self.mnemonic {
            wallet = BitcoinWallet(encryptedMnemonic: ownerMnemonic,
                                   password: password,
                                   acceptDefaultWalletMnemonic: true)

        }

        let isNewWallet: Bool
        if wallet?.mnemonic == nil {
            wallet = BitcoinWallet.withRandomEntropy()
            isNewWallet = true
        } else {
            isNewWallet = false
        }

        guard let encryptedMnemonic = wallet?.encryptedMnemonic(withKey: password,
                                                                isDefaultWallet: isDefaultPassword) else {
            let error = NSError(domain: "Wallet doesn't have mnemonic",
                                code: 666)
            self.finishSyncingBitcoinWith(error: error)
            return
        }

        self.bitcoinStorage.saveMnemonic(encryptedMnemonic,
                                         password: password,
                                         isNewWallet: isNewWallet,
                                         isDefaultWalletPassword: isDefaultPassword)
        self.finishSyncingBitcoinWith(error: nil)
    }

    func createNewDefaultWallet() {
        guard let defaultPassword = self.defaultWalletLogic?.defaultWalletPasswordFor?(synchronizationProcess: self) else {
            let error = NSError(domain: "To create default wallets, " +
                    "delegate must return password in -defaultBitcoinWalletPasswordForWelcomeViewController:",
                                code: 1)
            self.finishSyncingBitcoinWith(error: error)
            return
        }
        self.savePassword(defaultPassword, isDefaultPassword: true)
    }

    func finishSyncingBitcoinWith(error: Error?) {
        self.bitcoinSyncManager.cancelOperationSequence()
        self.bitcoinSyncCompletion?(error)
        self.bitcoinSyncCompletion = nil
    }
}
