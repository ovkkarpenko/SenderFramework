//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension MWLocationFacade: SettingsLocationManagerProtocol {}

@objc public class SettingsModule: NSObject, SettingsModuleProtocol {

    private weak var router: SettingsRouter?

    var blockedUsersModule: BlockedUsersModuleProtocol
    @objc public var senderUI: SenderUIProtocol {
        didSet {
            self.router?.senderUI = self.senderUI
        }
    }

    var bitcoinSettingsModule: BitcoinSettingsModuleProtocol

    @objc public init(blockedUsersModule: BlockedUsersModuleProtocol,
                senderUI: SenderUIProtocol,
                bitcoinSettingsModule: BitcoinSettingsModuleProtocol) {
        self.blockedUsersModule = blockedUsersModule
        self.senderUI = senderUI
        self.bitcoinSettingsModule = bitcoinSettingsModule
    }

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            settings: Settings,
                            forDelegate delegate: SettingsModuleDelegate?,
                            completion: (() -> Void)?) {
        let settingsDataManager = SettingsDataManager()
        let locationManager = MWLocationFacade.sharedInstance()
        let settingsEraser = SettingsEraser()
        let settingsInteractor = SettingsInteractor(dataManager: settingsDataManager,
                                                    locationManager: locationManager,
                                                    settingsEraser: settingsEraser)
        let settingsRouter = SettingsRouter(blockedUsersModule: self.blockedUsersModule,
                                            senderUI: self.senderUI,
                                            bitcoinSettingsModule: self.bitcoinSettingsModule)
        let settingsPresenter = SettingsPresenter(interactor: settingsInteractor, router: settingsRouter)
        settingsInteractor.updateWith(settings: settings)
        settingsInteractor.presenter = settingsPresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(settingsInteractor)
        settingsRouter.presenter = settingsPresenter
        settingsRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = settingsRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    @objc public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }
}
