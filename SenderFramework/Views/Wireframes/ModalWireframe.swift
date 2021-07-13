//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol ModalWireframeEventsHandler {
    @objc func prepareForPresentationWith(modalWireframe: ModalWireframe)
    @objc func prepareForDismissalWith(modalWireframe: ModalWireframe)
}

@objc public class ModalWireframe: NSObject, ViewControllerWireframe {

    @objc public var animatedPresentation: Bool = false
    @objc public private(set) weak var rootView: UIViewController?

    @objc public init(rootView: UIViewController) {
        self.rootView = rootView
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        self.callPrepareForPresentationWith(view: view)
        rootView.present(view, animated: self.animatedPresentation, completion: completion)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        guard let presentedController = rootView.presentedViewController,
              presentedController == view else { return }

        self.callPrepareForDismissalWith(view: view)
        rootView.dismiss(animated: self.animatedPresentation, completion: completion)
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? ModalWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(modalWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? ModalWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(modalWireframe: self)
        }
    }
}

extension ModalWireframe: WireframeProtocol {}
