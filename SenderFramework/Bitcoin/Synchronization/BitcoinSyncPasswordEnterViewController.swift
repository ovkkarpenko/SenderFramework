//
//  BitcoinSyncPasswordEnterViewController.swift
//  SENDER
//
//  Created by Roman Serga on 28/1/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

class BitcoinSyncPasswordEnterViewController: BitcoinSyncPasswordEnterScreen {

    @IBOutlet var cancelButton : UIBarButtonItem!
    @IBOutlet weak var passwordTextField : UITextField!
    @IBOutlet weak var promptLabel : UILabel!
    @IBOutlet weak var secondaryActionButton : UIButton!

    @IBOutlet weak var passwordFieldCenter: NSLayoutConstraint!
    
    var passwordFieldCenterInitial = CGFloat(0.0)
    
    var submitButton : UIButton!
    
    override var disableCancel : Bool {
        didSet {
            if isViewLoaded {
                fixCancelButtonState()
            }
        }
    }
    
    override var secondaryButtonTitle : String? {
        didSet {
            if isViewLoaded {
                fixSecondaryActionButtonState()
            }
        }
    }

    @IBOutlet weak var passwordUnderline : UIView!
    
    override var inputAccessoryView : UIView {
        return submitButton
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        
        passwordFieldCenterInitial = passwordFieldCenter.constant
        passwordTextField.attributedPlaceholder = SenderCore.shared().stylePalette.placeholder(with: SenderFrameworkLocalizedString("bitcoin_password", comment: ""))
        passwordTextField.textColor = SenderCore.shared().stylePalette.mainTextColor

        submitButton = UIButton(type: .system)
        submitButton.frame = CGRect(x: 0.0, y: self.view.frame.size.height - mainActionButtonHeight, width: self.view.frame.size.width, height: mainActionButtonHeight);
        submitButton.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor
        submitButton.setTitleColor(SenderCore.shared().stylePalette.actionButtonTitleColor, for: UIControlState())
        submitButton.setTitle(SenderFrameworkLocalizedString("bitcoin_enter_password_submit_button_title", comment: "").uppercased(), for: UIControlState())
        submitButton.addTarget(self, action: #selector(BitcoinSyncPasswordEnterViewController.submitPassword), for: .touchUpInside)

        SenderCore.shared().stylePalette.customize(self.navigationController?.navigationBar)
        title = ""
        
        promptLabel.text = promptString
        promptLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        passwordUnderline.backgroundColor = SenderCore.shared().stylePalette.lineColor
        
        fixCancelButtonState()
        fixSecondaryActionButtonState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BitcoinSyncPasswordEnterViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BitcoinSyncPasswordEnterViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BitcoinSyncPasswordEnterViewController.startPasswordInput), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func startPasswordInput() {
        passwordTextField.becomeFirstResponder()
    }
    
    func fixCancelButtonState() {
        if disableCancel {
            self.navigationItem.setRightBarButton(nil, animated: false)
        } else {
            self.navigationItem.setRightBarButton(cancelButton, animated: false)
        }
    }
    
    func fixSecondaryActionButtonState() {
        secondaryActionButton.isHidden = (secondaryButtonTitle == nil)
        secondaryActionButton.setTitle(secondaryButtonTitle, for: UIControlState())
        
        if secondaryButtonTitle != nil {
            let attributedTitle = NSAttributedString(string: secondaryButtonTitle!, attributes: [NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue, NSAttributedStringKey.foregroundColor : SenderCore.shared().stylePalette.secondaryTextColor])
            secondaryActionButton.setAttributedTitle(attributedTitle, for: UIControlState())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passwordTextField.text = ""
        startPasswordInput()
        if IS_IPHONE_4_OR_LESS {
            moveKeyboardUp()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func submitPassword() {
        if let enteredPassword = passwordTextField.text {
            syncManager?.submitPassword(enteredPassword, sender: self)
        }
    }
    
    @IBAction func cancel(_ sender : AnyObject) {
        syncManager?.cancelOperationSequence()
    }
    
    @IBAction func secondaryAction(_ sender : AnyObject) {
        syncManager?.secondaryButtonPressedOnPasswordScreen(self)
    }

    override func showAlert(_ alertString: String, completion: (() -> Void)?) {
        promptLabel.text = alertString
        promptLabel.textColor = SenderCore.shared().stylePalette.alertColor
        passwordTextField.isUserInteractionEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64((UInt64(2) * NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
            
            self.promptLabel.text = self.promptString
            self.promptLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor
            self.passwordTextField.isUserInteractionEnabled = true
            
            if self.presentedViewController is UIAlertController {
                self.passwordTextField.endEditing(true)
                self.view.endEditing(true)
                self.resignFirstResponder()
            }
            
            completion?()
        }
    }
    
    @objc func keyboardWillShow(_ notification : Notification) {
        if shouldMoveKeyboardUp() {
            self.moveKeyboardUp()
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(_ notification : Notification) {
        if shouldMoveKeyboardDown() {
            self.moveKeyboardDown()
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func shouldMoveKeyboardUp() -> Bool {
        return passwordTextField.isFirstResponder && IS_IPHONE_4_OR_LESS
    }
    
    func moveKeyboardUp() {
        self.passwordFieldCenter.constant = -100
    }
    
    func shouldMoveKeyboardDown() -> Bool {
        return IS_IPHONE_4_OR_LESS
    }
    
    func moveKeyboardDown() {
        self.passwordFieldCenter.constant = self.passwordFieldCenterInitial
    }
    
}
