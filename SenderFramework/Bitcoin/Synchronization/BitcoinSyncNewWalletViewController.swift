//
//  BitcoinSyncNewWalletViewController.swift
//  SENDER
//
//  Created by Roman Serga on 20/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

class BitcoinSyncNewWalletViewController: BitcoinSyncNewWalletScreen {
    
    var newMnemonic : BTCMnemonic?

    @IBOutlet weak var wordsListTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func close(_ sender: AnyObject) {
    }
    
    @IBAction func ok(_ sender: AnyObject) {
        syncManager?.finishWithMnemonic(newMnemonic, sender: self)
    }
    
    @IBAction func generateNewWallet(_ sender: AnyObject) {
        newMnemonic = BTCMnemonic.randomMnemonic(withPassword: nil, andWordListType: .english)
        if let wordsParsed = newMnemonic?.words as? [String] {
            wordsListTextView.text = wordsParsed.joined(separator: " ")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
