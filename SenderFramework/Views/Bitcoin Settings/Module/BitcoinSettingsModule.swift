//
// Created by Roman Serga on 26/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BitcoinSettingsModule: BitcoinSettingsModuleProtocol {

    private weak var router: BitcoinSettingsRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                            completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, completion: completion)
            return
        }

        let bitcoinSettingsDataManager = BitcoinSettingsDataManager()
        let bitcoinSettingsInteractor = BitcoinSettingsInteractor(dataManager: bitcoinSettingsDataManager)
        let bitcoinSettingsRouter = BitcoinSettingsRouter()
        let bitcoinSettingsPresenter = BitcoinSettingsPresenter(interactor: bitcoinSettingsInteractor,
                                                              router: bitcoinSettingsRouter)
        bitcoinSettingsInteractor.presenter = bitcoinSettingsPresenter
        bitcoinSettingsRouter.presenter = bitcoinSettingsPresenter
        bitcoinSettingsRouter.presentViewWith(wireframe: wireframe, completion: completion)
        self.router = bitcoinSettingsRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}
