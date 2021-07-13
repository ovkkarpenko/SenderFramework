//
// Created by Roman Serga on 14/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class MainScreenRouter: MainScreenRouterProtocol {
    var presenter: MainScreenPresenterProtocol?

    var chatListModule: ChildChatListModuleProtocol
    var userProfileModule: ChildUserProfileModuleProtocol

    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?
    private var currentWireframe: ViewControllerWireframe?
    private weak var currentView: MainScreenView?

    init(chatListModule: ChildChatListModuleProtocol,
         userProfileModule: ChildUserProfileModuleProtocol) {
        self.chatListModule = chatListModule
        self.userProfileModule = userProfileModule
    }

    var mainScreenView: MainScreenView {
        if let existingView = self.currentView {
            return existingView
        } else {
            let newView = self.buildContainerView()
            self.currentView = newView
            return newView
        }
    }

    func buildContainerView() -> MainScreenView {
        return MainScreenView()
    }

    private func getViewAndPrepareForPresentation() -> MainScreenView {
        let mainScreenView = self.mainScreenView
        mainScreenView.presenter = self.presenter
        self.presenter?.view = mainScreenView
        return mainScreenView
    }

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType, completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.currentView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let mainScreenView = self.getViewAndPrepareForPresentation()
        wireframe.presentView(mainScreenView) {}
        self.currentGenericWireframe = AnyWireframeWithAnyRootView(wireframe)
    }

    func presentViewWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?) {
        let mainScreenView = self.getViewAndPrepareForPresentation()
        wireframe.presentView(mainScreenView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentContainerView = self.currentView else { return }
        self.currentWireframe?.dismissView(currentContainerView, completion: completion)
        self.currentGenericWireframe?.dismissView(currentContainerView, completion: completion)
    }

    func showChatList() {
        guard let containerView = self.currentView else { return }
        let chatListWireframe = AddToContainerInNavigationWireframe(rootView: containerView)
        self.chatListModule.presentWith(wireframe: chatListWireframe, forDelegate: self.presenter, completion: nil)
    }

    func showUserProfile() {
        guard let containerView = self.currentView else { return }
        let userProfileWireframe = AddToContainerWireframe(rootView: containerView)
        self.userProfileModule.presentWith(wireframe: userProfileWireframe,
                                           forDelegate: self.presenter,
                                           completion: nil)
    }

    func presentChildViews() {
        guard let containerView = self.currentView else { return }

        let userProfileWireframe = AddToContainerWireframe(rootView: containerView)
        let chatListWireframe = AddToContainerInNavigationWireframe(rootView: containerView)

        self.userProfileModule.presentWith(wireframe: userProfileWireframe,
                                           forDelegate: self.presenter,
                                           completion: nil)
        self.chatListModule.presentWith(wireframe: chatListWireframe, forDelegate: self.presenter, completion: nil)
    }
}