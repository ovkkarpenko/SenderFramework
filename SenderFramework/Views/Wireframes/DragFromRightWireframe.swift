//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol DragWireframeDelegate: class {
    @objc optional func dragWireframeWillStartMovingView(_ dragWireframe: DragFromRightWireframe)
    @objc optional func dragWireframeDidMoveView(_ dragWireframe: DragFromRightWireframe)
    @objc optional func dragWireframeDidEndMovingView(_ dragWireframe: DragFromRightWireframe)
    @objc optional func dragWireframeDidPresentView(_ dragWireframe: DragFromRightWireframe)
    @objc optional func dragWireframeDidDismissView(_ dragWireframe: DragFromRightWireframe)
}

@objc public protocol DragFromRightWireframeEventsHandler {
    @objc func prepareForPresentationWith(dragFromRightWireframe: DragFromRightWireframe)
    @objc func prepareForDismissalWith(dragFromRightWireframe: DragFromRightWireframe)
}

@objc public class DragFromRightWireframe: NSObject, ViewControllerWireframe {

    private let panGestureRecognizer: UIPanGestureRecognizer
    private var shouldHandleDrag = true
    private weak var childView: UIViewController?
    weak var delegate: DragWireframeDelegate?

    @objc public private(set) var isChildViewVisible = false
    @objc public var animatedPresentation: Bool = true

    @objc public var presentationTime: TimeInterval = 0.3
    @objc public var activeZoneWidth: CGFloat = 70.0
    @objc public var minimalOffset: CGFloat = 100.0

    @objc public private(set) weak var rootView: UIViewController?

    @objc public var isGestureRecognizerEnabled: Bool {
        set {
            self.panGestureRecognizer.isEnabled = newValue
        }
        get {
            return self.panGestureRecognizer.isEnabled
        }
    }

    private var startViewPosition: CGFloat { return (self.rootView?.view.frame.maxX ?? 0.0) + 1.0 }

    @objc public init(rootView: UIViewController) {
        self.rootView = rootView
        self.panGestureRecognizer = UIPanGestureRecognizer()
        super.init()
        self.panGestureRecognizer.addTarget(self, action: #selector(DragFromRightWireframe.handleDragWith))
        self.panGestureRecognizer.minimumNumberOfTouches = 1
        self.panGestureRecognizer.maximumNumberOfTouches = 1
        rootView.view.addGestureRecognizer(self.panGestureRecognizer)
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        self.callPrepareForPresentationWith(view: view)
        if let currentChildView = self.childView { self.dismissView(currentChildView, completion: completion) }
        let newChildView = view
        rootView.addChildViewController(newChildView)
        rootView.view.addSubview(newChildView.view)
        var viewFrame = newChildView.view.frame
        viewFrame.origin.x = self.startViewPosition
        newChildView.view.frame = viewFrame
        self.isChildViewVisible = false
        self.childView = newChildView

        self.delegate?.dragWireframeDidPresentView?(self)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        self.callPrepareForDismissalWith(view: view)

        if view.view.superview == rootView.view {
            view.view.removeFromSuperview()
        }
        if rootView.childViewControllers.contains(view) {
            view.removeFromParentViewController()
        }
        self.delegate?.dragWireframeDidDismissView?(self)
    }

    @objc public func showCurrentView() {
        self.setChildViewVisible(true, callDelegateStartMethod: true)
    }

    @objc public func hideCurrentView() {
        self.setChildViewVisible(false, callDelegateStartMethod: true)
    }

    func setChildViewVisible(_ visible: Bool,
                             callDelegateStartMethod: Bool = false,
                             completion: ((Bool) -> Void)? = nil) {
        guard self.childView != nil else { return }
        if callDelegateStartMethod { self.delegate?.dragWireframeWillStartMovingView?(self) }

        self.isChildViewVisible = visible
        let newX: CGFloat = self.isChildViewVisible ? 0.0 : self.startViewPosition
        UIView.animate(withDuration: self.animatedPresentation ? self.presentationTime : 0,
                       delay: 0.0,
                       options: .beginFromCurrentState,
                       animations: { self.moveChildViewWith(newX: newX)}) { completed in
            self.delegate?.dragWireframeDidEndMovingView?(self)
            completion?(completed)
        }
    }

    func moveChildViewWith(newX: CGFloat? = nil, newY: CGFloat? = nil) {
        guard let childView = self.childView else { return }

        var viewFrame = childView.view.frame
        viewFrame.origin.x = newX ?? viewFrame.origin.x
        viewFrame.origin.y = newY ?? viewFrame.origin.y
        childView.view.frame = viewFrame
        self.delegate?.dragWireframeDidMoveView?(self)
    }

    @objc func handleDragWith(panGestureRecognizer: UIPanGestureRecognizer) {
        guard let childView = self.childView, let rootView = self.rootView else { return }

        panGestureRecognizer.view?.layer.removeAllAnimations()
        let translatedPoint: CGPoint = panGestureRecognizer.translation(in: rootView.view)
        let touchPoint: CGPoint = panGestureRecognizer.location(in: rootView.view)

        if panGestureRecognizer.state == .began {
            let touchPointXToHandleDrag = rootView.view.frame.maxX - self.activeZoneWidth
            if touchPoint.x >= touchPointXToHandleDrag || self.isChildViewVisible {
                self.shouldHandleDrag = true
                self.delegate?.dragWireframeWillStartMovingView?(self)
            }
        } else if panGestureRecognizer.state == .ended {
            setChildViewVisible(self.isChildViewVisible)
            self.shouldHandleDrag = false
        } else if panGestureRecognizer.state == .changed {
            if self.shouldHandleDrag {
                let fingerPositionX = panGestureRecognizer.location(in: rootView.view).x
                let fingerPositionXToShowChildView = rootView.view.frame.size.width - self.minimalOffset
                self.isChildViewVisible = fingerPositionX < fingerPositionXToShowChildView
                if childView.view.frame.origin.x + translatedPoint.x >= 0 {
                    self.moveChildViewWith(newX: childView.view.frame.origin.x + translatedPoint.x)
                }
                let newTranslation = CGPoint(x: 0, y: 0)
                panGestureRecognizer.setTranslation(newTranslation, in: rootView.view)
            }
        }
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? DragFromRightWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(dragFromRightWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? DragFromRightWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(dragFromRightWireframe: self)
        }
    }
}

extension DragFromRightWireframe: WireframeProtocol {}
