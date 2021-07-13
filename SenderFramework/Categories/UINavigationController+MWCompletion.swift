//
// Created by Roman Serga on 25/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension UINavigationController {

    public func mw_pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion?()
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }

    public func mw_popViewController(animated: Bool, completion: (() -> Void)?) -> UIViewController? {
        let poppedController = popViewController(animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion?()
            return poppedController
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
        return poppedController
    }

    public func mw_setViewControllers(_ viewControllers: [UIViewController],
                                      animated: Bool,
                                      completion: (() -> Void)?) {
        setViewControllers(viewControllers, animated: animated)

        guard animated, let coordinator = transitionCoordinator else {
            completion?()
            return
        }

        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
        return
    }
}
