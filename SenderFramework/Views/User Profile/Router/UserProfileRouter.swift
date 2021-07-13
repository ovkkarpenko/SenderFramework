//
// Created by Roman Serga on 26/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserProfileRouter: UserProfileRouterProtocol {

    weak var presenter: UserProfilePresenterProtocol?

    var qrScreenModule: QRScreenModuleProtocol
    var senderUI: SenderUIProtocol

    fileprivate weak var currentUserProfileView: UserProfileViewController?
    fileprivate var currentWireframe: ViewControllerWireframe?

    init(qrScreenModule: QRScreenModuleProtocol, senderUI: SenderUIProtocol) {
        self.qrScreenModule = qrScreenModule
        self.senderUI = senderUI
    }

    var userProfileView: UserProfileViewController {
        if let existingView = self.currentUserProfileView {
            return existingView
        } else {
            let newView = self.buildUserProfileView()
            self.currentUserProfileView = newView
            return newView
        }
    }

    func buildUserProfileView() -> UserProfileViewController {
        return UserProfileViewController.loadFromSenderFrameworkStoryboardWith(name: "Main")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: UserProfileModuleDelegate?)
                    -> UserProfileViewController {
        let userProfileView = self.userProfileView
        userProfileView.presenter = self.presenter
        self.presenter?.view = userProfileView
        self.presenter?.delegate = moduleDelegate
        return userProfileView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: UserProfileModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentUserProfileView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let userProfileView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(userProfileView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentUserProfileView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.dismissQRScreen()
        self.dismissView(completion: completion)
    }

    func presentQRScreenWith(qrString: String) {
        guard let currentView = self.currentUserProfileView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentView)
        self.qrScreenModule.presentWith(wireframe: wireframe,
                                        qrString: qrString,
                                        forDelegate: self.presenter,
                                        completion: nil)
    }

    func dismissQRScreen() {
        self.qrScreenModule.dismiss(completion: nil)
    }

    func presentSettings() {
        _ = self.senderUI.showSettings(animated: true, modally: false, forDelegate: nil)
    }

    func presentTopUpMobileScreen() {
        _ = self.senderUI.showRobotScreenWith(model: CallRobotModel.topUpMobile,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }

    func presentTransferMoneyScreen() {
        _ = self.senderUI.showRobotScreenWith(model: CallRobotModel.transferMobile,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }

    func presentWalletScreen() {
        _ = self.senderUI.showRobotScreenWith(model: CallRobotModel.wallet,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }

    func presentStoreScreen() {
        _ = self.senderUI.showRobotScreenWith(model: CallRobotModel.store,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }

    func presentCreateRobotScreen() {
        _ = self.senderUI.showRobotScreenWith(model: CallRobotModel.createRobot,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }

}

class ChildUserProfileRouter: UserProfileRouter, ChildUserProfileRouterProtocol {

    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: UserProfileModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.currentUserProfileView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let userProfileView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(userProfileView, completion: completion)
    }

    override func dismissView(completion: (() -> Void)?) {
        super.dismissView(completion: nil)
        guard let currentView = self.currentUserProfileView else { return }
        self.currentGenericWireframe?.dismissView(currentView, completion: completion)
    }
}
