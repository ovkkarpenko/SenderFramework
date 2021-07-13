//
// Created by Roman Serga on 16/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(MWChatScrollToBottomViewDelegate)
public protocol ChatScrollToBottomViewDelegate: class {
    func chatScrollToBottomViewWasPressed(_ chatScrollToBottomView: ChatScrollToBottomView)
}

@objc(MWChatScrollToBottomView)
public class ChatScrollToBottomView: UIView {

    @IBOutlet public weak var button: UIButton! {
        didSet {
            let borderWidth = CGFloat(1.0) / UIScreen.main.scale
            self.button.layer.borderWidth = borderWidth
            self.button.layer.borderColor = SenderCore.shared().stylePalette.lineColor.cgColor
        }
    }

    @IBOutlet public weak var counterBackground: UIView! {
        didSet {
            self.counterBackground.backgroundColor = SenderCore.shared().stylePalette.alertColor
        }
    }

    @IBOutlet public weak var counter: UILabel!

    fileprivate weak var counterBackgroundWidth: NSLayoutConstraint?
    fileprivate weak var counterBackgroundHeight: NSLayoutConstraint?

    weak var delegate: ChatScrollToBottomViewDelegate?

    var isCounterHidden: Bool = false {
        didSet {
            if self.isCounterHidden {
                self.hideCounter()
            } else {
                self.showCounter()
            }
        }
    }

    @IBAction func buttonWasPressed(sender: UIView) {
        self.delegate?.chatScrollToBottomViewWasPressed(self)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.button.layer.cornerRadius = self.button.frame.height / 2
        self.counterBackground.layer.cornerRadius = self.counterBackground.frame.height / 2
    }

    func showCounter() {
        guard let heightConstraint = self.counterBackgroundHeight,
              let widthConstraint = self.counterBackgroundWidth else { return }
        self.counterBackground.removeConstraints([heightConstraint, widthConstraint])
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    func hideCounter() {
        guard self.counterBackgroundHeight == nil, self.counterBackgroundWidth == nil else { return }

        let heightConstraint = NSLayoutConstraint(item: self.counterBackground,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 0.0)
        let widthConstraint = NSLayoutConstraint(item: self.counterBackground,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1.0,
                                                  constant: 0.0)
        self.counterBackground.addConstraints([heightConstraint, widthConstraint])
        self.counterBackgroundHeight = heightConstraint
        self.counterBackgroundWidth = widthConstraint
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
