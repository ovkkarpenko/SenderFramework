//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ModalInNavigationWireframeEventsHandler {
    @objc func prepareForPresentationWith(modalInNavigationWireframe: ModalInNavigationWireframe)
    @objc func prepareForDismissalWith(modalInNavigationWireframe: ModalInNavigationWireframe)
}

@objc public class ModalInNavigationWireframe: NSObject, ViewControllerWireframe {

    @objc public var animatedPresentation: Bool = true
    @objc public private(set) weak var rootView: UIViewController?

    @objc public init(rootView: UIViewController) {
        self.rootView = rootView
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        let navigationController = UINavigationController(rootViewController: view)
        self.callPrepareForPresentationWith(view: view)
        rootView.present(navigationController, animated: self.animatedPresentation, completion: completion)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        guard let presentedNavigationController = rootView.presentedViewController as? UINavigationController,
              let rootController = presentedNavigationController.viewControllers.first,
              rootController == view else { return }
        self.callPrepareForDismissalWith(view: view)
        rootView.dismiss(animated: self.animatedPresentation, completion: completion)
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? ModalInNavigationWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(modalInNavigationWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? ModalInNavigationWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(modalInNavigationWireframe: self)
        }
    }
}

extension ModalInNavigationWireframe: WireframeProtocol {}
