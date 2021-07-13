//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol CustomWireframeEventsHandler {
    @objc func prepareForPresentationWith(customWireframe: CustomWireframe)
    @objc func prepareForDismissalWith(customWireframe: CustomWireframe)
}

@objc public class CustomWireframe: NSObject, ViewControllerWireframe {

    @objc public var animatedPresentation: Bool = false
    @objc public var identifier: String?

    @objc public var presentViewClosure: (UIViewController, Bool, (() -> Void)?) -> Void
    @objc public var dismissViewClosure: (UIViewController, Bool, (() -> Void)?) -> Void

    @objc public init(presentViewClosure: @escaping (UIViewController, Bool, (() -> Void)?) -> Void,
                dismissViewClosure: @escaping (UIViewController, Bool, (() -> Void)?) -> Void) {
        self.presentViewClosure = presentViewClosure
        self.dismissViewClosure = dismissViewClosure
    }

    @objc public func presentView(_ view: UIViewController, completion: (() -> Void)?) {
        self.callPrepareForPresentationWith(view: view)
        self.presentViewClosure(view, self.animatedPresentation, completion)
    }

    @objc public func dismissView(_ view: UIViewController, completion: (() -> Void)?) {
        self.callPrepareForDismissalWith(view: view)
        self.dismissViewClosure(view, self.animatedPresentation, completion)
    }

    private func callPrepareForPresentationWith(view: UIViewController) {
        if let eventsHandler = view as? CustomWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(customWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: UIViewController) {
        if let eventsHandler = view as? CustomWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(customWireframe: self)
        }
    }
}
