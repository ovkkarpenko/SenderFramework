//
//  BitcoinSyncMainViewController.swift
//  SENDER
//
//  Created by Roman Serga on 20/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

class BitcoinSyncMainViewController: BitcoinSyncStartScreen {
    
    @IBOutlet weak var importWalletButton: UIButton!
    @IBOutlet weak var newWalletButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createNewWallet(_ sender: AnyObject) {
        syncManager?.showNewWalletScreen(self)
    }
    
    @IBAction func importWallet(_ sender: AnyObject) {
        syncManager?.showImportScreen(nil, sender: self)
    }

}
