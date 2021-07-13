//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserInfoEditorRouter: UserInfoEditorRouterProtocol {

    weak var presenter: UserInfoEditorPresenterProtocol?

    private weak var currentUserInfoEditorView: UserInfoEditorViewController?
    private var currentWireframe: ViewControllerWireframe?

    var userInfoEditorView: UserInfoEditorViewController {
        if let existingView = self.currentUserInfoEditorView {
            return existingView
        } else {
            let newView = self.buildUserInfoEditorView()
            self.currentUserInfoEditorView = newView
            return newView
        }
    }

    func buildUserInfoEditorView() -> UserInfoEditorViewController {
        return UserInfoEditorViewController.loadFromSenderFrameworkStoryboardWith(name: "UserInfoEditor")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: UserInfoEditorModuleDelegate?)
                    -> UserInfoEditorViewController {
        let userInfoEditorView = self.userInfoEditorView
        userInfoEditorView.presenter = self.presenter
        self.presenter?.view = userInfoEditorView
        self.presenter?.delegate = moduleDelegate
        return userInfoEditorView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: UserInfoEditorModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentUserInfoEditorView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let userInfoEditorView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(userInfoEditorView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let userInfoEditorView = self.currentUserInfoEditorView else { return }
        self.currentWireframe?.dismissView(userInfoEditorView, completion: completion)
    }
}
