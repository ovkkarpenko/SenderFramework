//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderSSOAuthorizationInteractor)
public class SenderSSOAuthorizationInteractor: NSObject, SenderAuthorizationInteractorProtocol {
    public weak var delegate: SenderAuthorizationInteractorDelegate?
    public var server: SenderAuthorizationServerProtocol
    public var dataManager: SenderAuthorizationDataManagerProtocol

    public init(server: SenderAuthorizationServerProtocol, dataManager: SenderAuthorizationDataManagerProtocol) {
        self.server = server
        self.dataManager = dataManager
        super.init()
    }

    public func startAuthorizationWith(model: SenderAuthorizationModel, completion: AuthorizationStartCompletion?) {
        self.server.sendAuthorizationRequestWith(model: model) { registrationStatusModel, error in

            guard let registrationResult = registrationStatusModel, error == nil else {
                self.delegate?.senderAuthorizationInteractor(self, didFailedAuthorizationWithModel: nil)
                completion?(nil, error)
                return
            }

            registrationResult.step = .userInfo
            self.delegate?.senderAuthorizationInteractor(self, didPerformedRegistrationWith: registrationResult)
            completion?(registrationStatusModel, error)
        }
    }

    public func deauthorizeWith(model: SenderDeauthorizationModel, completion: DeauthorizationCompletion?) {
        self.server.sendDeauthorizationRequestWith(model: model) { error in
            if let error = error {
                self.delegate?.senderAuthorizationInteractor(self, didFailedDeauthorizationWithError: error)
            } else {
                self.delegate?.senderAuthorizationInteractorDidFinishedDeauthorization(self)
            }
        }
    }

    public func loadUserInfo(completion: AuthorizationStepCompletion?) {
        self.server.loadUserInfo { response, error in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            if let userInfo = response { self.dataManager.saveUserInfo(userInfo) }
            let stepModel = SenderAuthorizationStepModel(step: .success)
            stepModel.additionalData = response as? [String: Any]
            stepModel.error = error
            completion?(stepModel, nil)
            self.handleStepModel(stepModel)
        }
    }

    func handleStepModel(_ stepModel: SenderAuthorizationStepModel) {
        if stepModel.step == .failure {
            self.delegate?.senderAuthorizationInteractor(self, didFailedAuthorizationWithModel: stepModel)
        } else if stepModel.step == .success {
            self.delegate?.senderAuthorizationInteractor(self, didFinishedAuthorizationWithModel: stepModel)
        } else if stepModel.step == .name {
            self.delegate?.senderAuthorizationInteractor(self, didAuthorizedAsNewUserWithModel: stepModel)
        }
    }
}
