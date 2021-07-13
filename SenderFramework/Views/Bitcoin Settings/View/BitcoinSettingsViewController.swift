//
//  BitcoinSettingsViewController.swift
//  SENDER
//
//  Created by Roman Serga on 25/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

open class BitcoinSettingsViewController: UITableViewController,
                                          BitcoinSettingsViewProtocol,
                                          BitcoinSyncManagerDelegate,
                                          BitcoinSyncManagerDataSource {

    @IBOutlet weak var walletCell: UITableViewCell!

    @IBOutlet weak var exportCell: UITableViewCell! {
        didSet {
            exportCell.textLabel?.text = SenderFrameworkLocalizedString("bitcoin_wallet_export", comment: "")
        }
    }

    @IBOutlet weak var importCell: UITableViewCell! {
        didSet {
            importCell.textLabel?.text = SenderFrameworkLocalizedString("bitcoin_wallet_import", comment: "")
        }
    }

    @IBOutlet weak var newWalletCell: UITableViewCell! {
        didSet {
            newWalletCell.textLabel?.text = SenderFrameworkLocalizedString("bitcoin_wallet_create_new", comment: "")
        }
    }

    @IBOutlet weak var changePasswordCell: UITableViewCell! {
        didSet {
            let key = "bitcoin_change_synchronization_password"
            changePasswordCell.textLabel?.text = SenderFrameworkLocalizedString(key, comment: "")
        }
    }

    @IBOutlet weak var bitcoinBalanceLabel: UILabel! {
        didSet {
            bitcoinBalanceLabel.text = ""
        }
    }

    @IBOutlet weak var dollarBalanceLabel: UILabel! {
        didSet {
            dollarBalanceLabel.text = ""
        }
    }

    @IBOutlet weak var addressTitleLabel: UILabel! {
        didSet {
            addressTitleLabel.text = SenderFrameworkLocalizedString("bitcoin_address", comment: "")
        }
    }

    @IBOutlet weak var addressLabel: UILabel! {
        didSet {
            addressLabel.text = ""
        }
    }

    public var syncManager: BitcoinSyncManager!

    var remoteWallet: BitcoinWallet!
    var currentWallet: BitcoinWallet!
    var remoteMnemonic: String?

    var presenter: BitcoinSettingsPresenterProtocol?

    // MARK: Implementation

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = SenderFrameworkLocalizedString("bitcoin_wallet", comment: "")

        self.syncManager = SenderCore.shared().bitcoinSyncManagerBuilder.syncManager(withRootViewController: self,
                                                                                     delegate: self)
        self.syncManager.dataSource = self

        self.tableView.backgroundColor = SenderCore.shared().stylePalette.commonTableViewBackgroundColor

        if SenderCore.shared().stylePalette.lineColor != nil {
            self.tableView.separatorColor = SenderCore.shared().stylePalette.lineColor
        }

        for cellLabel in [bitcoinBalanceLabel,
                          dollarBalanceLabel,
                          exportCell.textLabel,
                          importCell.textLabel,
                          newWalletCell.textLabel,
                          changePasswordCell.textLabel] {
            cellLabel?.textColor = SenderCore.shared().stylePalette.mainTextColor
        }

        for secondaryLabel in [addressTitleLabel, addressLabel] {
            secondaryLabel?.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }

        for cell in [walletCell, exportCell, importCell, newWalletCell, changePasswordCell] {
            cell?.contentView.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
            cell?.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        }

        self.presenter?.viewWasLoaded()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func updateWith(walletInfo: BitcoinWalletInfoProtocol) {
        self.refreshControl?.endRefreshing()
        guard let address = walletInfo.address else {
            self.showCannotGetWalletError()
            return
        }

        addressLabel.text = address

        let bitcoinBalanceText: String
        if let bitcoinBalance = walletInfo.bitcoinBalance {
            let bitcoinCurrencyCode = SenderFrameworkLocalizedString("btc_ccy", comment: "").uppercased()
            bitcoinBalanceText = bitcoinBalance + " " + bitcoinCurrencyCode
        } else {
            bitcoinBalanceText = SenderFrameworkLocalizedString("bitcoin_getting_balance", comment: "")
        }
        self.bitcoinBalanceLabel.text = bitcoinBalanceText

        let dollarBalanceText: String
        if let dollarBalance = walletInfo.dollarBalance {
            let dollarCurrencyCode = SenderFrameworkLocalizedString("usd_ccy", comment: "").uppercased()
            dollarBalanceText = dollarBalance + " " + dollarCurrencyCode
        } else {
            dollarBalanceText = ""
        }

        dollarBalanceLabel.text = dollarBalanceText
    }

    func showCannotGetWalletError() {
        bitcoinBalanceLabel.text = SenderFrameworkLocalizedString("bitcoin_cannot_get_wallet", comment: "")
        dollarBalanceLabel.text = ""
        addressLabel.text = SenderFrameworkLocalizedString("bitcoin_no_address", comment: "")
    }

    func showCannotGetBalanceError() {
        bitcoinBalanceLabel.text = ""
        dollarBalanceLabel.text = ""
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func showWalletImportAlert() {

        let importAlertTitle = SenderFrameworkLocalizedString("bitcoin_import_alert_title", comment: "")
        let importAlertMessage = SenderFrameworkLocalizedString("bitcoin_import_alert_message", comment: "")
        let actionSheet = UIAlertController(title: importAlertTitle,
                                            message: importAlertMessage,
                                            preferredStyle: .actionSheet)

        let importButtonTitle = SenderFrameworkLocalizedString("bitcoin_import_button_text", comment: "")
        let createAction = UIAlertAction(title: importButtonTitle,
                                         style: .destructive) { _ in
            self.syncManager.startWalletImport(nil)
        }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel", comment: ""),
                                         style: .cancel,
                                         handler: nil)
        actionSheet.addAction(createAction)
        actionSheet.addAction(cancelAction)
        actionSheet.mw_safePresentIn(viewController: self, animated: true)
    }

    // MARK: BitcoinSyncManager Delegate

    public func bitcoinSyncManagerDidFinishedImportWithMnemonic(_ mnemonic: BTCMnemonic?, andError error: NSError?) {
        let wallet = BitcoinWallet(mnemonic: mnemonic)
        var error: NSError?
        CoreDataFacade.sharedInstance().getOwner().setMainWallet(wallet, error: &error, asDefaultWallet: false)

        guard error == nil else {

            return
        }
        ServerFacade.sharedInstance().sendCurrentWalletToServer()
        finishResolvingConflict()
    }

    public func bitcoinSyncManagerPasswordToCheck(_ syncManager: BitcoinSyncManager) -> String {
        return try! CoreDataFacade.sharedInstance().getOwner().getPassword()
    }

    func finishResolvingConflict() {
        remoteWallet = nil
        CoreDataFacade.sharedInstance().getOwner().walletState = .ready
        self.presenter?.updateData()
    }

    open func bitcoinSyncManagerWasCanceled() {
        if remoteWallet != nil {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    public func bitcoinSyncManagerDidFinishedCreatingPassword(_ password: String) {
        var error: NSError?
        CoreDataFacade.sharedInstance().getOwner().setPassword(password, error: &error, isDefaultWalletPassword: false)
        if error == nil {
            if remoteWallet == nil {
                ServerFacade.sharedInstance().sendCurrentWalletToServer()
            }
            self.presenter?.updateData()
        }
    }

    public func bitcoinSyncManagerIsRemotePasswordRight(_ password: String) -> Bool {
        let checkWallet = BitcoinWallet(encryptedMnemonic:self.remoteMnemonic,
                                        password: password,
                                        acceptDefaultWalletMnemonic: true)
        return checkWallet!.mnemonic != nil
    }

    // MARK: UITableView Delegate

    @IBAction func refresh(_ sender: UIRefreshControl) {
        self.presenter?.updateData()
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        switch tableView.cellForRow(at: indexPath)! {
        case exportCell:
            try? syncManager.startWalletExport(CoreDataFacade.sharedInstance().getOwner().getMainWallet().mnemonic)
            break
        case importCell:
            showWalletImportAlert()
            break
        case newWalletCell:
            syncManager.startWalletCreation()
            break
        case changePasswordCell:
            syncManager.startPasswordChanging()
        default:
            break
        }
    }
}
