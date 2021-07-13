//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderSSOAuthorizationPresenter)
public class SenderSSOAuthorizationPresenter: NSObject,
                                              SenderAuthorizationPresenterProtocol,
                                              SenderAuthorizationInteractorDelegate {

    public var interactor: SenderAuthorizationInteractorProtocol
    public weak var delegate: SenderAuthorizationModuleDelegate?

    public init(interactor: SenderAuthorizationInteractorProtocol) {
        self.interactor = interactor
        super.init()
        self.interactor.delegate = self
    }

    public func startAuthorizationWith(model: SenderAuthorizationModel) {
        self.interactor.startAuthorizationWith(model: model) { registrationModel, _ in
            guard let registrationModel = registrationModel else { return }

            if registrationModel.step == .userInfo {
                self.interactor.loadUserInfo(completion: nil)
            }
        }
    }

    public func deauthorizeWith(model: SenderDeauthorizationModel) {
        self.interactor.deauthorizeWith(model: model, completion: nil)
    }

    public func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                              didPerformedRegistrationWith model: SenderRegistrationModel) {
        self.delegate?.senderAuthorizationPresenter(self, didPerformedRegistrationWith: model)
    }

    public func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                              didAuthorizedAsNewUserWithModel model: SenderAuthorizationStepModel) {
        self.delegate?.senderAuthorizationPresenter(self, didAuthorizedAsNewUserWithModel: model)
    }

    public func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                              didFinishedAuthorizationWithModel model: SenderAuthorizationStepModel) {
        self.delegate?.senderAuthorizationPresenter(self, didFinishedAuthorizationWithModel: model)
    }

    public func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                              didFailedAuthorizationWithModel model: SenderAuthorizationStepModel?) {
        self.delegate?.senderAuthorizationPresenter(self, didFailedAuthorizationWithModel: model)
    }

    public func senderAuthorizationInteractorDidFinishedDeauthorization(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol) {
        self.delegate?.senderAuthorizationPresenterDidFinishedDeauthorization(self)
    }

    public func senderAuthorizationInteractor(_ senderAuthorizationInteractor: SenderAuthorizationInteractorProtocol,
                                              didFailedDeauthorizationWithError error: Error) {
        self.delegate?.senderAuthorizationPresenter(self, didFailedDeauthorizationWithError: error)
    }
}