//
// Created by Roman Serga on 14/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

protocol MainScreenViewProtocol: class {
    var presenter: MainScreenPresenterProtocol? { get set }
}

protocol MainScreenPresenterProtocol: class, ChatListModuleDelegate, UserProfileModuleDelegate {
    weak var view: MainScreenViewProtocol? { get set }
    var router: MainScreenRouterProtocol? { get set }

    func viewWasLoaded()
    func showChatList()
    func showUserProfile()
}

protocol MainScreenRouterProtocol: class {

    weak var presenter: MainScreenPresenterProtocol? { get set }

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType, completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
    func presentViewWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)

    func presentChildViews()
    func showChatList()
    func showUserProfile()
}

@objc public protocol MainScreenModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}