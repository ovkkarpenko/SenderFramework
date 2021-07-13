//
// Created by Roman Serga on 3/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol ViewControllerWireframe {
    var animatedPresentation: Bool { get set }

    func presentView(_ view: UIViewController, completion: (() -> Void)?)
    func dismissView(_ view: UIViewController, completion: (() -> Void)?)
}

public protocol WireframeProtocol {
    associatedtype RootViewType: AnyObject
    associatedtype ChildViewType

    weak var rootView: RootViewType? { get }

    func presentView(_ view: ChildViewType, completion: (() -> Void)?)
    func dismissView(_ view: ChildViewType, completion: (() -> Void)?)
}

class WireFrame<RootViewType>: ViewControllerWireframe, WireframeProtocol where RootViewType: AnyObject {
    typealias ChildViewType = UIViewController

    var animatedPresentation: Bool = true

    private(set) weak var rootView: RootViewType?

    init(rootView: RootViewType) {
        self.rootView = rootView
    }

    func presentView(_ view: UIViewController, completion: (() -> Void)?) {}
    func dismissView(_ view: UIViewController, completion: (() -> Void)?) {}
}

struct AnyWireframe<RootViewType, ChildViewType>: WireframeProtocol where RootViewType: AnyObject {

    private(set) weak var rootView: RootViewType?

    private let _presentView: (ChildViewType, (() -> Void)?) -> Void
    private let _dismissView: (ChildViewType, (() -> Void)?) -> Void

    init<WireframeType: WireframeProtocol>(_ wireframe: WireframeType)
            where WireframeType.RootViewType == RootViewType,
            WireframeType.ChildViewType == ChildViewType {
        self.rootView = wireframe.rootView
        self._presentView = wireframe.presentView
        self._dismissView = wireframe.dismissView
    }

    func presentView(_ view: ChildViewType, completion: (() -> Void)?) {
        _presentView(view, completion)
    }

    func dismissView(_ view: ChildViewType, completion: (() -> Void)?) {
        _dismissView(view, completion)
    }
}

struct AnyWireframeWithAnyRootView<ChildViewType>: WireframeProtocol {

    private(set) weak var rootView: AnyObject?

    private let _presentView: (ChildViewType, (() -> Void)?) -> Void
    private let _dismissView: (ChildViewType, (() -> Void)?) -> Void

    init<WireframeType: WireframeProtocol>(_ wireframe: WireframeType)
            where WireframeType.ChildViewType == ChildViewType {
        self.rootView = wireframe.rootView as AnyObject?
        self._presentView = wireframe.presentView
        self._dismissView = wireframe.dismissView
    }

    func presentView(_ view: ChildViewType, completion: (() -> Void)?) {
        _presentView(view, completion)
    }

    func dismissView(_ view: ChildViewType, completion: (() -> Void)?) {
        _dismissView(view, completion)
    }
}