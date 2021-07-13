//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit
class SubviewContainerViewController: UIViewController, ContainerViewProtocol {

    var childViews: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func setChildViews(_ childViewsToSet: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        let oldChatViews = self.childViews
        for viewController in oldChatViews { self.dismissChildView(viewController, animated: false, completion: nil) }
        for viewController in self.childViews { self.presentChildView(viewController,
                                                                      animated: animated,
                                                                      completion: completion) }
    }

    func presentChildView(_ view: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.dismissChildView(view, animated: false, completion: nil)

        self.childViews.append(view)
        self.addChildViewController(view)
        self.view.addSubview(view.view)
        view.view.translatesAutoresizingMaskIntoConstraints = false
        let layoutAttributes: [NSLayoutAttribute] = [.top, .leading, .trailing, .bottom]
        for layoutAttribute in layoutAttributes {
            let constraint = NSLayoutConstraint(item: self.view,
                                                attribute: layoutAttribute,
                                                relatedBy: .equal,
                                                toItem: view.view,
                                                attribute: layoutAttribute,
                                                multiplier: 1.0,
                                                constant: 0.0)
            self.view.addConstraint(constraint)
        }

        if animated {
            let originalAlpha = view.view.alpha
            view.view.alpha = 0.0
            UIView.animate(withDuration: 0.3,
                           animations: { view.view.alpha = originalAlpha },
                           completion: { _ in completion?() })
        } else {
            completion?()
        }
    }

    func dismissChildView(_ view: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if let childViewIndex = self.childViews.index(of: view) { self.childViews.remove(at: childViewIndex) }

        if view.parent == self { view.removeFromParentViewController() }

        if view.view.superview == self.view {
            if animated {
                UIView.animate(withDuration: 0.3,
                               animations: { view.view.alpha = 0.0 },
                               completion: { _ in
                                   view.view.removeFromSuperview()
                                   completion?()
                               })
            } else {
                view.view.removeFromSuperview()
                completion?()
            }
        }
    }

}
