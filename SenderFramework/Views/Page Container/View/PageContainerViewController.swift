//
// Created by Roman Serga on 19/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class PageContainerViewController: UIPageViewController,
                                   ContainerViewProtocol,
                                   UIPageViewControllerDelegate,
                                   UIPageViewControllerDataSource {

    var childViews: [UIViewController] = []

    var viewControllersToSet: [UIViewController] = []
    var pageScrollView: UIScrollView?

    var currentViewController: UIViewController? {
        return self.viewControllers?.last
    }

    convenience init() {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    override init(transitionStyle style: UIPageViewControllerTransitionStyle,
                  navigationOrientation: UIPageViewControllerNavigationOrientation,
                  options: [String : Any]? = nil) {
        super.init(transitionStyle: style, navigationOrientation: navigationOrientation, options: options)
        self.delegate = self
        self.dataSource = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
        self.dataSource = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.pageScrollView = self.view.subviews.flatMap({$0 as? UIScrollView}).first
    }

    func setChildViews(_ childViewsToSet: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        self.childViews = childViewsToSet
        let newPageControllers = self.childViews.last != nil ? [self.childViews.last!] : nil
        self.setViewControllers(newPageControllers, direction: .forward, animated: animated) { _ in completion?() }
    }

    func presentChildView(_ view: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if !self.childViews.contains(view) { self.childViews.append(view) }
        let direction = self.directionForSettingController(view)
        self.setViewControllers([view], direction: direction, animated: animated) { _ in completion?() }
    }

    func dismissChildView(_ view: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let viewIndex = self.childViews.index(of: view) else { return }
        if let nextViewController = self.controllerToSetAfterDeletingController(view) {
            self.presentChildView(nextViewController, animated: animated, completion: completion)
        }
        self.childViews.remove(at: viewIndex)
    }

    private func directionForSettingController(_ controller: UIViewController)
                    -> UIPageViewControllerNavigationDirection {
        guard let currentController = self.currentViewController,
              let currentControllerIndex = self.childViews.index(of: currentController),
              let newControllerIndex = self.childViews.index(of:controller) else { return .forward }

        return newControllerIndex < currentControllerIndex ? .reverse : .forward
    }

    private func controllerToSetAfterDeletingController(_ controller: UIViewController) -> UIViewController? {
        guard let currentlyVisibleController = self.currentViewController,
              controller == currentlyVisibleController,
              let viewIndex = self.childViews.index(of: controller) else { return nil }

        let nextViewController: UIViewController?
        if self.childViews.count > 1 {
            let nextControllerIndex: Int
            if viewIndex > self.childViews.startIndex {
                nextControllerIndex = self.childViews.index(before: viewIndex)
            } else {
                nextControllerIndex = self.childViews.index(after: viewIndex)
            }
            nextViewController = self.childViews[nextControllerIndex]
        } else {
            nextViewController = nil
        }
        return nextViewController
    }

    override func setViewControllers(_ viewControllers: [UIViewController]?,
                                     direction: UIPageViewControllerNavigationDirection,
                                     animated: Bool,
                                     completion: ((Bool) -> Void)? = nil) {
        guard !(self.pageScrollView?.isDecelerating ?? false) else { return }

        /*
            For UIPageController with scroll transition style we must set array containing exactly one view controller
        */
        guard let newViewControllers = viewControllers, newViewControllers.count == 1 else { return }

        let isEqualViewControllerArrays: ([UIViewController]?, [UIViewController]?) -> Bool = { vcAr1, vcAr2 -> Bool in
            guard vcAr1 != nil, vcAr2 != nil else { return true }
            guard let vcAr1 = vcAr1, let vcAr2 = vcAr2 else { return false }
            return vcAr1 == vcAr2
        }

        guard !isEqualViewControllerArrays(newViewControllers, self.viewControllers) else { return }

        self.viewControllersToSet = newViewControllers

        func finishSettingControllers(completed: Bool) {
            self.viewControllersToSet = []
            completion?(completed)
        }

        if self.viewControllersToSet.count == 0, isEqualViewControllerArrays(newViewControllers, self.viewControllers) {
            super.setViewControllers(newViewControllers,
                                     direction: direction,
                                     animated: false,
                                     completion: finishSettingControllers)
        }

        super.setViewControllers(newViewControllers,
                                 direction: direction,
                                 animated: animated) { completed in
            guard completed else {
                finishSettingControllers(completed: completed)
                return
            }

            if animated {
                DispatchQueue.main.async {
                    super.setViewControllers(newViewControllers,
                                             direction: direction,
                                             animated: false,
                                             completion: finishSettingControllers)
                }
            } else {
                finishSettingControllers(completed: true)
            }
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentControllerIndex = self.childViews.index(of: viewController) else { return nil }
        let nextIndex = currentControllerIndex - 1
        return (nextIndex >= 0 && nextIndex < self.childViews.count) ? self.childViews[nextIndex] : nil
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentControllerIndex = self.childViews.index(of: viewController) else { return nil }
        let nextIndex = currentControllerIndex + 1
        return (nextIndex >= 0 && nextIndex < self.childViews.count) ? self.childViews[nextIndex] : nil
    }
}
