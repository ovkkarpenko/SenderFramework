//
// Created by Roman Serga on 24/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol EmptyInputAccessoryViewDelegate: NSObjectProtocol {
    @objc optional func emptyInputAccessoryView(_ emptyInputAccessoryView: EmptyInputAccessoryView,
                                                didChangeFrame newFrame: CGRect)
    @objc optional func emptyInputAccessoryViewDidBecomeInactive(_ emptyInputAccessoryView: EmptyInputAccessoryView)
}

@objc public class EmptyInputAccessoryView: UIView {
    @objc public weak var delegate: EmptyInputAccessoryViewDelegate?
    private var heightConstraint: NSLayoutConstraint?

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
    }

    @objc public func setHeight(_ height: CGFloat) {
        self.heightConstraint?.constant = height
        self.setNeedsLayout()
    }

    deinit {
        if let superview = superview { stopObservingChangesOf(superview) }
    }

    @objc public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        stopObservingChangesOf(superview)
        startObservingChangesOf(newSuperview)
        if let newSuperview = newSuperview {
            self.sendFrameUpdateIn(superview: newSuperview)
        } else {
            self.delegate?.emptyInputAccessoryViewDidBecomeInactive?(self)
        }
    }

    @objc public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.heightConstraint = self.constraints.first { constraint -> Bool in
            guard let firstItemAsView = constraint.firstItem as? EmptyInputAccessoryView else { return false }
            return firstItemAsView == self && constraint.firstAttribute == .height && constraint.secondItem == nil
        }
    }

    func startObservingChangesOf(_ view: UIView?) {
        view?.addObserver(self, forKeyPath: "center", context: nil)
    }

    func stopObservingChangesOf(_ view: UIView?) {
        view?.removeObserver(self, forKeyPath: "center")
    }

    @objc public override func observeValue(forKeyPath keyPath: String?,
                                            of object: Any?,
                                            change: [NSKeyValueChangeKey: Any]?,
                                            context: UnsafeMutableRawPointer?) {
        guard let observedView = object as? UIView, let superview = self.superview, observedView == superview else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if Thread.isMainThread {
            self.sendFrameUpdateIn(superview: superview)
        } else {
            DispatchQueue.main.async { self.sendFrameUpdateIn(superview: superview) }
        }
    }

    func sendFrameUpdateIn(superview: UIView) {
        var newFrame = superview.frame
        newFrame.size.height = self.heightConstraint?.constant ?? self.frame.height
        newFrame.origin.y -= newFrame.size.height
        self.delegate?.emptyInputAccessoryView?(self, didChangeFrame: newFrame)
    }
}
