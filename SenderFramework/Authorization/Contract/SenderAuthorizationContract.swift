//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderAuthorizationModuleDelegate)
public protocol SenderAuthorizationModuleDelegate: class {
    func senderAuthorizationPresenter(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol,
                                      didPerformedRegistrationWith model: SenderRegistrationModel)

    func senderAuthorizationPresenter(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol,
                                      didAuthorizedAsNewUserWithModel model: SenderAuthorizationStepModel)

    func senderAuthorizationPresenter(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol,
                                      didFinishedAuthorizationWithModel model: SenderAuthorizationStepModel)

    func senderAuthorizationPresenter(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol,
                                      didFailedAuthorizationWithModel model: SenderAuthorizationStepModel?)

    func senderAuthorizationPresenterDidFinishedDeauthorization(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol)

    func senderAuthorizationPresenter(_ senderAuthorizationPresenter: SenderAuthorizationPresenterProtocol,
                                      didFailedDeauthorizationWithError error: Error)
}

@objc(MWSenderAuthorizationPresenterProtocol)
public protocol SenderAuthorizationPresenterProtocol {
    typealias AuthorizationStartCompletion = (SenderRegistrationModel?, Error?) -> Void
    typealias DeauthorizationCompletion = (Error?) -> Void

    weak var delegate: SenderAuthorizationModuleDelegate? { get set }

    func startAuthorizationWith(model: SenderAuthorizationModel)
    func deauthorizeWith(model: SenderDeauthorizationModel)
}

@objc(MWSenderFullAuthorizationInteractorDelegate)
public protocol SenderAuthorizationInteractorDelegate: class {
    func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                       didPerformedRegistrationWith model: SenderRegistrationModel)

    func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                       didAuthorizedAsNewUserWithModel model: SenderAuthorizationStepModel)

    func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                       didFinishedAuthorizationWithModel model: SenderAuthorizationStepModel)

    func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                       didFailedAuthorizationWithModel model: SenderAuthorizationStepModel?)

    func senderAuthorizationInteractorDidFinishedDeauthorization(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol)

    func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                       didFailedDeauthorizationWithError error: Error)
}

@objc(MWSenderAuthorizationServerProtocol)
public protocol SenderAuthorizationServerProtocol {
    func sendAuthorizationRequestWith(model: SenderAuthorizationModel,
                                      completion: SenderAuthorizationInteractorProtocol.AuthorizationStartCompletion?)

    func sendDeauthorizationRequestWith(model: SenderDeauthorizationModel,
                                        completion: SenderAuthorizationInteractorProtocol.DeauthorizationCompletion?)

    func loadUserInfo(completion: (([AnyHashable: Any]?, Error?) -> Void)?)
}

@objc(MWSenderAuthorizationInteractorProtocol)
public protocol SenderAuthorizationInteractorProtocol {
    typealias AuthorizationStartCompletion = (SenderRegistrationModel?, Error?) -> Void
    typealias DeauthorizationCompletion = (Error?) -> Void
    typealias AuthorizationStepCompletion = (SenderAuthorizationStepModel?, Error?) -> Void

    weak var delegate: SenderAuthorizationInteractorDelegate? { get set }

    func startAuthorizationWith(model: SenderAuthorizationModel, completion: AuthorizationStartCompletion?)
    func deauthorizeWith(model: SenderDeauthorizationModel, completion: DeauthorizationCompletion?)
    func loadUserInfo(completion: AuthorizationStepCompletion?)
}

@objc(MWSenderAuthorizationDataManagerProtocol)
public protocol SenderAuthorizationDataManagerProtocol: class {
    @objc func saveUserInfo(_ userInfo: [AnyHashable: Any])
}

@objc(SenderAuthorizationRouterProtocol)
public protocol SenderAuthorizationRouterProtocol {
    func showStartScreen()
    func showDeauthorizationScreen()

    func showSuccessScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
    func showFailureScreenWithModel(_ stepModel: SenderAuthorizationStepModel)

    func showError(_ error: Error, completion: ((Bool) -> Void)?)
}

@objc(MWSenderAuthorizationModuleProtocol)
public protocol SenderAuthorizationModuleProtocol {
    func startAuthorizationWith(model: SenderAuthorizationModel)
    func deauthorizeWith(model: SenderDeauthorizationModel)
}
