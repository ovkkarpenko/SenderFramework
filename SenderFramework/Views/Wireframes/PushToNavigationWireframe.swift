//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol PushToNavigationWireframeEventsHandler {
    @objc func prepareForPresentationWith(pushToNavigationWireframe: PushToNavigationWireframe)
    @objc func prepareForDismissalWith(pushToNavigationWireframe: PushToNavigationWireframe)
}

@objc public class PushToNavigationWireframe: NSObject, ViewControllerWireframe {

    @objc public var animatedPresentation: Bool = true

    @objc public private(set) weak var rootView: UINavigationController?

    @objc public init(rootView: UINavigationController) {
        self.rootView = rootView
    }

    @objc public func setViews(_ views: [UIViewController], completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        for view in rootView.childViewControllers { self.callPrepareForPresentationWith(view: view) }
        for view in views { self.callPrepareForPresentationWith(view: view) }
        rootView.mw_setViewControllers(views, animated: self.animatedPresentation, completion: completion)
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        if let controllerIndex = rootView.viewControllers.index(of: view) {
            rootView.viewControllers.remove(at: controllerIndex)
        }

        self.callPrepareForPresentationWith(view: view)
        rootView.mw_pushViewController(view, animated: self.animatedPresentation, completion: completion)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        if let topViewController = rootView.topViewController, topViewController == view {
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

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? PushToNavigationWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(pushToNavigationWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? PushToNavigationWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(pushToNavigationWireframe: self)
        }
    }
}

extension PushToNavigationWireframe: WireframeProtocol {}
