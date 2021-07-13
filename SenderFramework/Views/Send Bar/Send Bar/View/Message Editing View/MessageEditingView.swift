//
// Created by Roman Serga on 11/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(MWMessageEditingViewDelegate)
public protocol MessageEditingViewDelegate: class {
    func messageEditingViewDidCancelEditing(_ messageEditingView: MessageEditingView)
}

@objc(MWMessageEditingView)
public class MessageEditingView: UIView {
    @IBOutlet public weak var editTitle: UILabel!
    @IBOutlet public weak var messageText: UILabel!
    @IBOutlet public weak var leftLine: UIView!
    @IBOutlet public weak var cancelButton: UIButton! {
        didSet {
            self.cancelButton.setImage(UIImage(fromSenderFrameworkNamed: "deleteButton"), for: .normal)
        }
    }

    @objc public weak var delegate: MessageEditingViewDelegate?

    @objc public override var tintColor: UIColor! {
        didSet {
            leftLine.backgroundColor = self.tintColor
            editTitle.textColor = self.tintColor
        }
    }

    @IBAction func cancelEditing(sender: UIView) {
        self.delegate?.messageEditingViewDidCancelEditing(self)
    }
}
