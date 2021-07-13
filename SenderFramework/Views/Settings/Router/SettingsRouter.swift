//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SettingsRouter: SettingsRouterProtocol {

    weak var presenter: SettingsPresenterProtocol?

    var blockedUsersModule: BlockedUsersModuleProtocol
    var senderUI: SenderUIProtocol
    var bitcoinSettingsModule: BitcoinSettingsModuleProtocol

    init(blockedUsersModule: BlockedUsersModuleProtocol,
         senderUI: SenderUIProtocol,
         bitcoinSettingsModule: BitcoinSettingsModuleProtocol) {
        self.blockedUsersModule = blockedUsersModule
        self.senderUI = senderUI
        self.bitcoinSettingsModule = bitcoinSettingsModule
    }

    private weak var currentSettingsView: SettingsViewController?
    private var currentWireframe: ViewControllerWireframe?

    var settingsView: SettingsViewController {
        if let existingView = self.currentSettingsView {
            return existingView
        } else {
            let newView = self.buildSettingsView()
            self.currentSettingsView = newView
            return newView
        }
    }

    func buildSettingsView() -> SettingsViewController {
        return SettingsViewController.loadFromSenderFrameworkStoryboardWith(name: "Settings")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: SettingsModuleDelegate?)
                    -> SettingsViewController {
        let settingsView = self.settingsView
        settingsView.presenter = self.presenter
        self.presenter?.view = settingsView
        self.presenter?.delegate = moduleDelegate
        return settingsView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: SettingsModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentSettingsView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let settingsView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(settingsView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let settingsView = self.currentSettingsView else { return }
        self.currentWireframe?.dismissView(settingsView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.dismissBlockedUsersView()
        self.dismissView(completion: completion)
    }

    func presentBitcoinWalletView() {
        guard let navigationController = currentSettingsView?.navigationController else { return }
        let wireframe = PushToNavigationWireframe(rootView: navigationController)
        self.bitcoinSettingsModule.presentWith(wireframe: wireframe, completion: nil)
    }

    func presentActiveDevicesView() {
        _ = senderUI.showRobotScreenWith(model: CallRobotModel.activeDevices,
                                         animated: true,
                                         modally: false,
                                         delegate: nil)
    }

    func presentBlockedUsersView() {
        guard let settingsView = currentSettingsView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: settingsView)
        self.blockedUsersModule.presentWith(wireframe: wireframe, forDelegate: self.presenter, completion: nil)
    }

    func dismissBlockedUsersView() {
        self.blockedUsersModule.dismiss(completion: nil)
    }
}
