//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BitcoinSettingsRouter: BitcoinSettingsRouterProtocol {
    weak var presenter: BitcoinSettingsPresenterProtocol?

    private weak var currentBitcoinSettingsView: BitcoinSettingsViewController?
    private var currentWireframe: ViewControllerWireframe?

    var bitcoinSettingsView: BitcoinSettingsViewController {
        if let existingView = self.currentBitcoinSettingsView {
            return existingView
        } else {
            let newView = self.buildBitcoinSettingsView()
            self.currentBitcoinSettingsView = newView
            return newView
        }
    }

    func buildBitcoinSettingsView() -> BitcoinSettingsViewController {
        return BitcoinSettingsViewController.loadFromSenderFrameworkStoryboardWith(name: "Settings")
    }

    fileprivate func getViewAndPrepareForPresentation() -> BitcoinSettingsViewController {
        let bitcoinSettingsView = self.bitcoinSettingsView
        bitcoinSettingsView.presenter = self.presenter
        self.presenter?.view = bitcoinSettingsView
        return bitcoinSettingsView
    }

    func presentViewWith(wireframe: ViewControllerWireframe, completion: (() -> Void)?) {
        guard self.currentBitcoinSettingsView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let bitcoinSettingsView = self.getViewAndPrepareForPresentation()
        wireframe.presentView(bitcoinSettingsView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let bitcoinSettingsView = self.currentBitcoinSettingsView else { return }
        self.currentWireframe?.dismissView(bitcoinSettingsView, completion: completion)
    }

    func presentConflictResolvingScreen() {
        guard let currentView = self.currentBitcoinSettingsView else { return }
        BitcoinConflictResolver.shared.startConflictResolvingIn(rootViewController: currentView,
                                                                delegate: self.presenter)
    }
}
