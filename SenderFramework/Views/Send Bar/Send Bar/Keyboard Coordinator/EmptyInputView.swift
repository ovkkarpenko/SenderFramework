//
// Created by Roman Serga on 25/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class EmptyInputView: UIView {
    private var heightConstraint: NSLayoutConstraint?
    var heightToSet: CGFloat?

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = .clear
    }

    @objc public func setHeight(_ height: CGFloat) {
        guard let heightConstraint = self.heightConstraint else { self.heightToSet = height; return }
        heightConstraint.constant = height
        self.setNeedsLayout()
    }

    @objc public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.heightConstraint = self.constraints.first { constraint -> Bool in
            guard let firstItemAsView = constraint.firstItem as? EmptyInputView else { return false }
            return firstItemAsView == self && constraint.firstAttribute == .height && constraint.secondItem == nil
        }
        if let heightToSet = self.heightToSet, let heightConstraint = self.heightConstraint {
            heightConstraint.constant = heightToSet
            self.setNeedsLayout()
            self.heightToSet = nil
        }
    }
}
