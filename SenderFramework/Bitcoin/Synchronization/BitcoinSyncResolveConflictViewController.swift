//
//  BitcoinSyncMigrationViewController.swift
//  SENDER
//
//  Created by Roman Serga on 20/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

let walletCellID = "BitcoinResolveConflictWalletCell"
let addWalletCellID = "BitcoinAddWalletCell"

import UIKit

class BitcoinSyncResolveConflictCell: UITableViewCell {
    @IBOutlet weak var bitcoinBalanceLabel: UILabel!
    @IBOutlet weak var dollarBalanceLabel: UILabel!
    @IBOutlet weak var addressTitleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    override func awakeFromNib() {
        addressTitleLabel.text = SenderFrameworkLocalizedString("bitcoin_address", comment: "")
        addressTitleLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor

        bitcoinBalanceLabel.text = SenderFrameworkLocalizedString("bitcoin_getting_balance", comment: "")
        bitcoinBalanceLabel.textColor = SenderCore.shared().stylePalette.mainTextColor

        dollarBalanceLabel.text = ""
        dollarBalanceLabel.textColor = SenderCore.shared().stylePalette.mainTextColor

        addressLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor

        tintColor = SenderCore.shared().stylePalette.mainAccentColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }
}

class BitcoinSyncResolveConflictViewController: BitcoinSyncResolveConflictScreen,
                                                UITableViewDelegate,
                                                UITableViewDataSource {

    var chosenMnemonic: BTCMnemonic?
    var bitcoinMarketPrice: Double?

    var walletsArray = [[String: AnyObject]]()
    var hasCreatedNewWallet: Bool = false

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var acceptButtonHeight: NSLayoutConstraint!

    //MARK : Implementation

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.backgroundColor = SenderCore.shared().stylePalette.commonTableViewBackgroundColor
        self.tableView.separatorColor = SenderCore.shared().stylePalette.lineColor

        SenderCore.shared().stylePalette.customize(self.navigationController?.navigationBar)

        title = SenderFrameworkLocalizedString("bitcoin_wallet_sync_title", comment: "")

        tableView.rowHeight = UITableViewAutomaticDimension

        if cancelDisabled {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            cancelButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        }

        acceptButtonHeight.constant = mainActionButtonHeight

        acceptButton.setTitle(SenderFrameworkLocalizedString("bitcoin_accept", comment: "").uppercased(),
                              for: UIControlState())
        acceptButton.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor

        if let remoteWallet = BitcoinWallet(mnemonic: remoteMnemonic),
           let localWallet = BitcoinWallet(mnemonic: localMnemonic) {
            walletsArray.append(["title": SenderFrameworkLocalizedString("bitcoin_remote_wallet") as AnyObject,
                                 "wallets": [remoteWallet] as AnyObject])
            walletsArray.append(["title": SenderFrameworkLocalizedString("bitcoin_local_wallet") as AnyObject,
                                 "wallets": [localWallet] as AnyObject])

            let wallets = [remoteWallet, localWallet]
            for wallet in wallets {
                updateBalanceForWallet(wallet) { self.tableView.reloadData() }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.beginUpdates()
        let firstRowIndexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: firstRowIndexPath, animated: false, scrollPosition: .none)
        self.tableView(tableView, didSelectRowAt: firstRowIndexPath)
        tableView.endUpdates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateBalanceForWallet(_ wallet: BitcoinWallet, completion : (() -> Void)?) {

        ServerFacade.sharedInstance().getUnspentTransactions(for: wallet) { outputs, _ in
            if let txouts = outputs as? [BTCTransactionOutput] {
                wallet.unspentOutputs = txouts
                ServerFacade.sharedInstance().getBitcoinMarketPrice() { response, _ in
                    if let pricesDict = response as? [String : [String : AnyObject]] {
                        if let usdPrices = pricesDict["USD"] {
                            self.bitcoinMarketPrice = usdPrices["last"] as? Double
                            DispatchQueue.main.async(execute: { () -> Void in
                                completion?()
                            })
                        }
                    }
                }
            }
        }
    }

    //MARK : Actions

    @IBAction func useLocalWallet(_ sender: AnyObject) {
        self.syncManager?.finishWithMnemonic(chosenMnemonic, sender: self)
    }

    @IBAction func useServerWallet(_ sender: AnyObject) {
        self.syncManager?.showImportScreen(nil, sender: self)
    }

    @IBAction func createNewWallet(_ sender: AnyObject) {
        self.syncManager?.showNewWalletScreen(self)
    }

    @IBAction func cancel(_ sender: AnyObject) {
        self.syncManager?.cancelOperationSequence()
    }

    @IBAction func accept(_ sender: AnyObject) {
        if chosenMnemonic != nil {
            self.syncManager?.finishWithMnemonic(chosenMnemonic, sender: self)
        } else {

        }
    }

    @IBAction func importWallet(_ sender: AnyObject) {
        syncManager?.startWalletImport(nil)
    }

    @IBAction func createNew(_ sender: AnyObject) {
        syncManager?.startWalletCreation()
    }

    //MARK : TableView Delegate and Data Source

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < walletsArray.count {
            return walletsArray[section]["title"] as? String
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section < walletsArray.count {
            chosenMnemonic = walletForIndexPath(indexPath)!.mnemonic
        } else {
            hasCreatedNewWallet = true
            walletsArray.append(["title": SenderFrameworkLocalizedString("bitcoin_new_wallet") as AnyObject,
                                 "wallets": [BitcoinWallet.withRandomEntropy()] as AnyObject])
            let sectionNumber = walletsArray.count - 1
            self.tableView.reloadSections(IndexSet(integer: sectionNumber), with: .automatic)
            let lastRowIndexPath = IndexPath(row: tableView.numberOfRows(inSection: sectionNumber) - 1,
                                             section: sectionNumber)
            self.tableView.scrollToRow(at: lastRowIndexPath, at: .bottom, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let walletMnemonic = walletForIndexPath(indexPath)?.mnemonic,
              let chosenMnemonic = self.chosenMnemonic else { return }
        let isCellSelected = (walletMnemonic == chosenMnemonic)
        cell.setSelected(isCellSelected, animated: false)
    }

    func walletForIndexPath(_ indexPath: IndexPath) -> BitcoinWallet? {
        guard (indexPath as NSIndexPath).section < walletsArray.count else {
            return nil
        }

        if let wallets = walletsArray[(indexPath as NSIndexPath).section]["wallets"] as? [BitcoinWallet] {
            if (indexPath as NSIndexPath).row < wallets.count {
                return wallets[(indexPath as NSIndexPath).row]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return walletsArray.count + (hasCreatedNewWallet ? 0 : 1)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < walletsArray.count {
            return walletsArray[section]["wallets"]!.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116.0
    }

    func setWallet(_ wallet: BitcoinWallet, forCell cell: BitcoinSyncResolveConflictCell) {
        cell.addressLabel.text = wallet.paymentKey.compressedPublicKeyAddress.string

        if let balance = wallet.balance, let balanceDouble = Double(balance) {

            cell.bitcoinBalanceLabel.text = balance + " " + SenderFrameworkLocalizedString("btc_ccy").uppercased()

            if bitcoinMarketPrice != nil {
                cell.dollarBalanceLabel.text = NSString(format: "%.2f", balanceDouble * bitcoinMarketPrice!) as String + " " + SenderFrameworkLocalizedString("usd_ccy").uppercased()
            } else {
                cell.dollarBalanceLabel.text = ""
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section < walletsArray.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: walletCellID,
                                                     for: indexPath) as! BitcoinSyncResolveConflictCell
            setWallet(walletForIndexPath(indexPath)!, forCell: cell)
            cell.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: addWalletCellID, for: indexPath)
            cell.textLabel?.text = SenderFrameworkLocalizedString("bitcoin_wallet_create_new", comment: "")
            cell.textLabel?.textColor = SenderCore.shared().stylePalette.mainTextColor
            cell.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
            return cell
        }
    }

}
