//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderSSOAuthorizationModule)
public class SenderSSOAuthorizationModule: NSObject, SenderAuthorizationModuleProtocol {

    private var authorizationPresenter: SenderSSOAuthorizationPresenter

    @objc public init(delegate: SenderAuthorizationModuleDelegate?) {
        let authorizationDataManager = SenderAuthorizationDataManager()
        let authorizationServer = SenderFullAuthorizationServer()
        let authorizationInteractor = SenderSSOAuthorizationInteractor(server: authorizationServer,
                                                                       dataManager: authorizationDataManager)
        self.authorizationPresenter = SenderSSOAuthorizationPresenter(interactor: authorizationInteractor)
        self.authorizationPresenter.delegate = delegate
        super.init()
    }

    @objc public func startAuthorizationWith(model: SenderAuthorizationModel) {
        self.authorizationPresenter.startAuthorizationWith(model: model)
    }

    @objc public func deauthorizeWith(model: SenderDeauthorizationModel) {
        self.authorizationPresenter.deauthorizeWith(model: model)
    }
}
