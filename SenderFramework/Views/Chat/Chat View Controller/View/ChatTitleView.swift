//
// Created by Roman Serga on 16/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc (MWChatTitleViewDelegate)
protocol ChatTitleViewDelegate: class {
    func chatTitleViewDidPressChatTitle(_ chatTitleView: ChatTitleView)
}

@objc(MWChatTitleView)
public class ChatTitleView: UIView {

    weak var delegate: ChatTitleViewDelegate?

    @IBOutlet public weak var titleButton: UIButton! {
        didSet {
            titleButton.setTitleColor(.black, for: .normal)
            titleButton.setTitleColor(.lightGray, for: .highlighted)
            titleButton.adjustsImageWhenHighlighted = false
        }
    }

    @IBOutlet public weak var detailImageView: UIImageView!
    @IBOutlet public weak var subtitleLabel: UILabel! {
        didSet {
            self.subtitleLabel.textColor = UIColor(red: 143.0/255.0,
                                                   green: 143.0/255.0,
                                                   blue: 149.0/255.0,
                                                   alpha: 1.0)
        }
    }
    @IBOutlet public weak var subtitleBackground: UIView!
    @IBOutlet public weak var lockImage: UIImageView!
    @IBOutlet public weak var lockImageWidth: NSLayoutConstraint!

    public var title: String {
        set {
            self.titleButton.setTitle(newValue, for: .normal)
        }
        get {
            return self.titleButton.title(for: .normal) ?? ""
        }
    }

    public var subtitle: String {
        set {
            self.subtitleLabel.text = newValue
        }
        get {
            return self.subtitleLabel.text ?? ""
        }
    }

    public var isLockImageHidden: Bool = false {
         didSet {
             self.lockImageWidth.constant = self.isLockImageHidden ? 0.0 : self.lockImage.intrinsicContentSize.width
             self.setNeedsLayout()
             self.layoutIfNeeded()
         }
    }

    @IBAction func chatTitlePressed(sender: UIView) {
        self.delegate?.chatTitleViewDidPressChatTitle(self)
    }
}
