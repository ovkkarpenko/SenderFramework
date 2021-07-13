//
//  BitcoinSyncImportWalletViewController.swift
//  SENDER
//
//  Created by Roman Serga on 20/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

let tableViewWordCellID = "Word Search Cell"
let collectionViewWordCellID = "Word Cell"

let tableViewHeightLimit = Float((IS_IPHONE_5 || IS_IPHONE_4_OR_LESS) ? 0.0 : 132.0)
let wordsCountLimit = 12


import UIKit

protocol BitcoinMnemonicWordCellDelegate {
    func mnemonicWordCellDidPressedDetailButton(_ cell : BitcoinMnemonicWordCell)
}

class BitcoinMnemonicWordCell : UICollectionViewCell {
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var detailButton : UIButton!

    @IBOutlet weak var detailButtonTrailing : NSLayoutConstraint!
    
    var detailButtonTrailingInitial : CGFloat = 0.0
    
    var delegate : BitcoinMnemonicWordCellDelegate?
    
    var showsDetailButton : Bool = false {
        didSet {
            detailButton.isHidden = !showsDetailButton
            detailButtonTrailing.constant = showsDetailButton ? detailButtonTrailingInitial : 0.0
        }
    }

    override func awakeFromNib() {
        self.layer.borderWidth = 1.0
        self.layer.borderColor = SenderCore.shared().stylePalette.mainAccentColor.cgColor
        self.layer.cornerRadius = 4.0
        
        detailButtonTrailingInitial = detailButtonTrailing.constant
        
        self.titleLabel.textColor = SenderCore.shared().stylePalette.mainAccentColor
    }
    
    @IBAction func detailButtonTap(_ sender : UIButton) {
        self.delegate?.mnemonicWordCellDidPressedDetailButton(self)
    }
}

class CustomSearchTextField : UITextField {

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 20.0, y: bounds.origin.y, width: bounds.width - 40.0, height: bounds.height)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + 20.0, y: bounds.origin.y, width: bounds.width - 40.0, height: bounds.height)
    }
}

class BitcoinSyncImportWalletViewController: BitcoinSyncImportScreen,
                                             UICollectionViewDelegate,
                                             UICollectionViewDataSource,
                                             UICollectionViewDelegateFlowLayout,
                                             UITableViewDelegate,
                                             UITableViewDataSource,
                                             UITextFieldDelegate,
                                             BitcoinMnemonicWordCellDelegate,
                                             QRScannerModuleDelegate {

    @IBOutlet weak var wordsCollectionView: UICollectionView!

    @IBOutlet weak var scanQRButton: UIBarButtonItem!

    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var wordsSearchTableView: UITableView!
    @IBOutlet weak var searchTextField: CustomSearchTextField!
    @IBOutlet weak var counterLabel : UILabel!
    
    @IBOutlet var separatorViews: [UIView]!
    @IBOutlet weak var tableViewBackground: UIView!
    @IBOutlet weak var collectionViewBackground: UIView!
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewBackgroundHeight: NSLayoutConstraint!
    @IBOutlet var separatorViewsHeights: [NSLayoutConstraint]!
    
    var importButton: UIButton!

    var sizingCell: BitcoinMnemonicWordCell = {
        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        guard let cell = senderFrameworkBundle.loadNibNamed("BitcoinMnemonicWordCell", owner: nil, options: nil)?.first as? BitcoinMnemonicWordCell else {
            fatalError("Cannot load BitcoinMnemonicWordCell from nib")
        }

        return cell
    }()
    
    var mnemonicArray = [String]()
    var allSearchWordsArray = [String]()
    var visibleSearchWordsArray = [String]()

    var qrScannerModule: QRScannerModule?
    
    //MARK: Implementation
    
    override var inputAccessoryView : UIView {
        return importButton
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = SenderFrameworkLocalizedString("bitcoin_wallet_import_title", comment: "")

        self.view.backgroundColor = SenderCore.shared().stylePalette.commonTableViewBackgroundColor

        if SenderCore.shared().stylePalette.lineColor != nil {
            self.wordsSearchTableView.separatorColor = SenderCore.shared().stylePalette.lineColor
        }

        SenderCore.shared().stylePalette.customize(self.navigationController?.navigationBar)
        SenderCore.shared().stylePalette.customize(self.navigationItem)

        self.constructImportButton()

        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        let wordCellNib = UINib(nibName: "BitcoinMnemonicWordCell", bundle: senderFrameworkBundle)
        wordsCollectionView.register(wordCellNib, forCellWithReuseIdentifier: collectionViewWordCellID)
        wordsCollectionView.scrollsToTop = false
        wordsCollectionView.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor

        collectionViewBackground.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor

        tableViewBackground.backgroundColor = self.view.backgroundColor

        if let wodrsFilePath = SENDER_FRAMEWORK_BUNDLE.path(forResource: "BitcoinMnemonicWords", ofType: "plist") {
            allSearchWordsArray = NSArray(contentsOfFile: wodrsFilePath) as! [String]
        }
        visibleSearchWordsArray = allSearchWordsArray

        counterLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor

        searchTextField.textColor = SenderCore.shared().stylePalette.mainTextColor
        let placeholder = SenderFrameworkLocalizedString("bitcoin_enter_word", comment: "")
        searchTextField.attributedPlaceholder = SenderCore.shared().stylePalette.placeholder(with: placeholder)
        searchTextField.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor

        collectionViewHeight.constant -= IS_IPHONE_4_OR_LESS ? 50.0 : 0.0
        tableViewHeight.constant = CGFloat(tableViewHeightLimit)
        tableViewBackgroundHeight.constant = searchTextField.frame.size.height + CGFloat(tableViewHeightLimit)

        closeButton.image = UIImage(fromSenderFrameworkNamed: "close")
        closeButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor

        scanQRButton.image = UIImage(fromSenderFrameworkNamed: "_QR")
        scanQRButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor

        clearButton.setTitle(SenderFrameworkLocalizedString("clear", comment: ""), for: UIControlState())
        clearButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor

        _ = separatorViews.map { $0.backgroundColor = wordsSearchTableView.separatorColor }

        for separatorLineHeight in separatorViewsHeights {
            separatorLineHeight.constant = 1.0 / UIScreen.main.scale
        }
        updateCounter()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIResponder.becomeFirstResponder), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func constructImportButton() {
        importButton = UIButton(type: .system)
        importButton.frame = CGRect(x: 0.0, y: self.view.frame.size.height - mainActionButtonHeight, width: self.view.frame.size.width, height: mainActionButtonHeight)
        importButton.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor
        importButton.setTitleColor(SenderCore.shared().stylePalette.actionButtonTitleColor, for: UIControlState())
        importButton.setTitle(SenderFrameworkLocalizedString("bitcoin_enter_password_submit_button_title", comment: "").uppercased(), for: UIControlState())
        importButton.addTarget(self, action: #selector(BitcoinSyncImportWalletViewController.importWallet(_:)), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: Actions

    @objc func importWallet(_ sender: AnyObject) {
        
        if let mnemonic = BTCMnemonic(words: mnemonicArray, password: nil, wordListType: .english) {
            self.syncManager?.finishWithMnemonic(mnemonic, sender: self)
        } else {
            let alert = UIAlertController(title: SenderFrameworkLocalizedString("bitcoin_wrong_mnemonic_title", comment: ""), message: SenderFrameworkLocalizedString("bitcoin_wrong_mnemonic_message", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios", comment: ""), style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.syncManager?.cancelOperationSequence()
    }
    
    @IBAction func scanQR(_ sender: AnyObject) {
        self.qrScannerModule = QRScannerModule()
        let wireframe = ModalInNavigationWireframe(rootView: self)
        qrScannerModule?.presentWith(wireframe: wireframe, forDelegate: self, completion: nil)
    }
    
    @IBAction func clear(_ sender: AnyObject) {
        clearWords()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchTextField.endEditing(true)
    }
    
    //MARK: QRScannerModule Delegate

    func qrScannerModuleDidCancel() {
        self.qrScannerModule?.dismiss(completion: nil)
    }

    func qrScannerModuleDidFinishWith(string: String) {
        let wordsArray = string.components(separatedBy: " ")
        setWordsList(wordsArray)
        self.qrScannerModule?.dismiss(completion: nil)
    }
    
    //MARK: UICollectionView Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mnemonicArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewWordCellID, for: indexPath)
        if let wordCell = cell as? BitcoinMnemonicWordCell {
            configureCell(wordCell, forIndexPath: indexPath)
            wordCell.delegate = self
        }
        return cell
    }
    
    func configureCell(_ cell : BitcoinMnemonicWordCell, forIndexPath indexPath : IndexPath) {
        cell.showsDetailButton = ((indexPath as NSIndexPath).row == collectionView(wordsCollectionView, numberOfItemsInSection: 0) - 1)
        cell.titleLabel.text = mnemonicArray[(indexPath as NSIndexPath).row]
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let newSize = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        var newFrame = cell.frame
        newFrame.size = newSize
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        cell.frame = newFrame
        
        cell.detailButton.setImage(UIImage(fromSenderFrameworkNamed: "delete"), for: UIControlState())
        cell.detailButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        configureCell(sizingCell, forIndexPath: indexPath)
        let result = sizingCell.frame.size

        return result
    }

    func addWordsToList(_ words : [String]) {
        
        if mnemonicArray.count < wordsCountLimit {
            mnemonicArray.append(contentsOf: words)
            setWordsList(mnemonicArray)
        }
    }
    
    func removeWordAtIndex(_ index : Int) {
        mnemonicArray.remove(at: index)
        setWordsList(mnemonicArray)
    }
    
    func clearWords() {
        mnemonicArray = []
        setWordsList(mnemonicArray)
    }
    
    func setWordsList(_ words : [String]) {
        
        wordsCollectionView.performBatchUpdates(
            { () -> Void in
                self.mnemonicArray = words
                self.updateCounter()
                self.wordsCollectionView.reloadSections(IndexSet(integer: 0))
            })
            { (completed) -> Void in
                if self.mnemonicArray.count > 0 {
                    self.wordsCollectionView.scrollToItem(at: IndexPath(item: self.mnemonicArray.count - 1, section: 0), at: .bottom, animated: true)
                }
        }
    }
    
    func updateCounter() {
        clearButton.isHidden = mnemonicArray.count < 1
        counterLabel.text = NSString(format: SenderFrameworkLocalizedString("bitcoin_enter_word_count_text", comment: "") as NSString, String(mnemonicArray.count), String(wordsCountLimit)).uppercased as String
    }
    
    //MARK: UITableView Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSearchWordsArray.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewWordCellID, for: indexPath)
        cell.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        cell.textLabel?.textColor = SenderCore.shared().stylePalette.mainTextColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = visibleSearchWordsArray[(indexPath as NSIndexPath).row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        addWordsToList([visibleSearchWordsArray[(indexPath as NSIndexPath).row]])
        searchTextField.text = ""
    }
    
    //MARK: UITextField Methods
    
    @IBAction func textFieldTextDidChange(_ sender: UITextField) {
        if let searchText = sender.text {
            
            if searchText.characters.count > 0 {
                visibleSearchWordsArray = allSearchWordsArray.filter({$0.hasPrefix(searchText.lowercased())})
            } else {
                visibleSearchWordsArray = allSearchWordsArray
            }
            
            let newHeight = Float(visibleSearchWordsArray.count) * Float(self.tableView(wordsSearchTableView, heightForRowAt: IndexPath(row: 0, section: 0)))
            tableViewHeight.constant = CGFloat((newHeight <= tableViewHeightLimit) ? newHeight : tableViewHeightLimit)
            
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.wordsSearchTableView.layoutIfNeeded()
                }, completion: {(completed) -> Void in
                    self.wordsSearchTableView.reloadData()
            }) 
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !(string.characters.count != 0 && string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count == 0) else {
            _ = self.textFieldShouldReturn(textField)
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let word = textField.text {
            if allSearchWordsArray.contains(word) {
                addWordsToList([word])
                textField.text = ""
            }
        }
        return true
    }
    
    //MARK: BitcoinMnemonicWordCell Delegate
    
    func mnemonicWordCellDidPressedDetailButton(_ cell: BitcoinMnemonicWordCell) {
        if let path = wordsCollectionView.indexPath(for: cell) {
            removeWordAtIndex((path as NSIndexPath).item)
        }
    }
}
