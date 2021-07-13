//
//  BitcoinSyncExportWalletViewController.swift
//  SENDER
//
//  Created by Roman Serga on 20/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

class BitcoinSyncExportWalletViewController: BitcoinSyncExportScreen {
    
    @IBOutlet weak var closeButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = SenderFrameworkLocalizedString("bitcoin_wallet_export_title", comment: "")
        closeButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        self.view.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor

        SenderCore.shared().stylePalette.customize(self.navigationController?.navigationBar)
        SenderCore.shared().stylePalette.customize(self.navigationItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.syncManager?.cancelOperationSequence()
    }
}
