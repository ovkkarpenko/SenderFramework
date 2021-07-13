//
// Created by Roman Serga on 20/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class AddToContainerWireframe<RootViewType>: WireframeProtocol
        where RootViewType: ContainerViewProtocol {

    var animatedPresentation: Bool = true

    private(set) weak var rootView: RootViewType?

    required init(rootView: RootViewType) {
        self.rootView = rootView
    }

    func setViews(_ views: [RootViewType.ChildViewType], completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        for view in views { self.callPrepareForPresentationWith(view: view) }
        rootView.setChildViews(views, animated: self.animatedPresentation, completion: completion)
    }

    func presentView(_ view: RootViewType.ChildViewType, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        self.callPrepareForPresentationWith(view: view)
        rootView.presentChildView(view, animated: self.animatedPresentation, completion: completion)
    }

    func dismissView(_ view: RootViewType.ChildViewType, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }
        self.callPrepareForDismissalWith(view: view)
        rootView.dismissChildView(view, animated: self.animatedPresentation, completion: completion)
    }

    private func callPrepareForPresentationWith(view: RootViewType.ChildViewType) {
        if let eventsHandler = view as? AddToContainerWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(addToContainerWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: RootViewType.ChildViewType) {
        if let eventsHandler = view as? AddToContainerWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(addToContainerWireframe: self)
        }
    }
}

@objc public protocol AddToContainerWireframeEventsHandler {
    //addToContainerWireframe doesn't have specific type in order to be used in objective-c
    @objc func prepareForPresentationWith(addToContainerWireframe: Any)
    @objc func prepareForDismissalWith(addToContainerWireframe: Any)
}
