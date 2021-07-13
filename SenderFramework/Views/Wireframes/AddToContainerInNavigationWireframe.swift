//
// Created by Roman Serga on 26/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class AddToContainerInNavigationWireframe<RootViewType>: WireframeProtocol
        where RootViewType: UIViewController,
        RootViewType: ContainerViewProtocol,
        RootViewType.ChildViewType == UIViewController {

    private(set) weak var rootView: RootViewType?
    var animatedPresentation: Bool = true

    required init(rootView: RootViewType) {
        self.rootView = rootView
    }

    func setViews(_ views: [RootViewType.ChildViewType], completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        let viewsInNavigationControllers = views.map { view -> UINavigationController in
            let navigationController = UINavigationController(rootViewController: view)
            self.callPrepareForPresentationWith(view: view)
            return navigationController
        }
        rootView.setChildViews(viewsInNavigationControllers, animated: self.animatedPresentation, completion: completion)
    }

    func presentView(_ view: RootViewType.ChildViewType, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        let newViewInNavigationController = view.navigationController ?? UINavigationController(rootViewController: view)
        self.callPrepareForPresentationWith(view: view)
        let childView = newViewInNavigationController
        rootView.presentChildView(childView, animated: self.animatedPresentation, completion: completion)
    }

    func dismissView(_ view: RootViewType.ChildViewType, completion: (() -> Void)?) {
        guard let rootView = self.rootView else { return }

        let filteredViews = rootView.childViewControllers.filter { (childView) -> Bool in
            guard let childNavigationController = childView as? UINavigationController else {
                return childView == view
            }

            guard let navigationRootController = childNavigationController.viewControllers.first else {
                return childNavigationController == view
            }

            return navigationRootController == view
        }
        if let viewToDismiss = filteredViews.first {
            self.callPrepareForDismissalWith(view: viewToDismiss)
            rootView.dismissChildView(viewToDismiss, animated: self.animatedPresentation, completion: completion)
        }
    }

    private func callPrepareForPresentationWith(view: RootViewType.ChildViewType) {
        if let eventsHandler = view as? AddToContainerInNavigationWireframeEventsHandler {
            eventsHandler.prepareForPresentationWith(addToContainerInNavigationWireframe: self)
        }
    }

    private func callPrepareForDismissalWith(view: RootViewType.ChildViewType) {
        if let eventsHandler = view as? AddToContainerInNavigationWireframeEventsHandler {
            eventsHandler.prepareForDismissalWith(addToContainerInNavigationWireframe: self)
        }
    }
}

@objc public protocol AddToContainerInNavigationWireframeEventsHandler {
    //addToContainerInNavigationWireframeEventsHandler doesn't have specific type in order to be used in objective-c
    @objc func prepareForPresentationWith(addToContainerInNavigationWireframe: Any)
    @objc func prepareForDismissalWith(addToContainerInNavigationWireframe: Any)
}
