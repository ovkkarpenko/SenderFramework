//
// Created by Roman Serga on 4/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(MWFirstResponderViewDelegate)
public protocol FirstResponderViewDelegate: class {
    @objc optional func firstResponderViewDidBecomeFirstResponder(_ firstResponderView: FirstResponderView)
    @objc optional func firstResponderViewDidResignFirstResponder(_ firstResponderView: FirstResponderView)
    @objc optional func firstResponderViewShouldBecomeFirstResponder(_ firstResponderView: FirstResponderView) -> Bool
}

@objc(MWFirstResponderView)
public class FirstResponderView: UIView {

    @objc public weak var delegate: FirstResponderViewDelegate?

    @objc public override var canBecomeFirstResponder: Bool {
        return self.delegate?.firstResponderViewShouldBecomeFirstResponder?(self) ?? true
    }

   @objc public override func becomeFirstResponder() -> Bool {
        let returnValue = super.becomeFirstResponder()
        self.delegate?.firstResponderViewDidBecomeFirstResponder?(self)
        return returnValue
    }

    @objc public override func resignFirstResponder() -> Bool {
        let returnValue = super.resignFirstResponder()
        self.delegate?.firstResponderViewDidResignFirstResponder?(self)
        return returnValue
    }
}
