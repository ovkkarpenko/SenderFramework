//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol SetToNavigationWireframeEventsHandler {
    @objc func prepareForPresentationWith(setToNavigationWireframe: SetToNavigationWireframe)
    @objc func prepareForDismissalWith(setToNavigationWireframe: SetToNavigationWireframe)
}

@objc public class SetToNavigationWireframe: NSObject, ViewControllerWireframe {

    @objc public var animatedPresentation: Bool = true

    @objc public private(set) weak var rootView: UINavigationController?

    @objc public init(rootView: UINavigationController) {
        self.rootView = rootView
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        self.callPrepareForPresentationWith(view: view)
        rootView.mw_setViewControllers([view], animated: self.animatedPresentation, completion: completion)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        if let topViewController = self.rootView?.topViewController, topViewController == view {
            self.callPrepareForDismissalWith(view: view)
            _ = rootView.mw_popViewController(animated: self.animatedPresentation, completion: completion)
        } else {
            if let viewControllerIndex = rootView.viewControllers.index(of: view) {
                self.callPrepareForDismissalWith(view: view)
                var newViewControllers = rootView.viewControllers
                newViewControllers.remove(at: viewControllerIndex)
                rootView.mw_setViewControllers(newViewControllers, animated: false, completion: completion)
            }
        }
    }

    @objc public func setViews(_ views: [UIViewController], completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        for view in views { self.callPrepareForPresentationWith(view: view) }
        rootView.mw_setViewControllers(views, animated: self.animatedPresentation, completion: completion)
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? SetToNavigationWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(setToNavigationWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? SetToNavigationWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(setToNavigationWireframe: self)
        }
    }
}

extension SetToNavigationWireframe: WireframeProtocol {}
