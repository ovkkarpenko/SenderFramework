//
// Created by Roman Serga on 29/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderFullAuthorizationInteractor)
public class SenderFullAuthorizationInteractor: NSObject, SenderFullAuthorizationInteractorProtocol {

    public var server: SenderFullAuthorizationServerProtocol
    public var dataManager: SenderAuthorizationDataManagerProtocol

    public weak var delegate: SenderAuthorizationInteractorDelegate?
    private var currentStep: SenderAuthorizationStep = .none

    public init(server: SenderFullAuthorizationServerProtocol,
                dataManager: SenderAuthorizationDataManagerProtocol) {
        self.server = server
        self.dataManager = dataManager
        super.init()
    }

    public func startAuthorizationWith(model: SenderAuthorizationModel,
                                       completion: SenderAuthorizationInteractorProtocol.AuthorizationStartCompletion?) {
        self.currentStep = .initialization
        self.server.sendAuthorizationRequestWith(model: model) { registrationStatusModel, error in

            guard let registrationResult = registrationStatusModel, error == nil else {
                self.delegate?.senderAuthorizationInteractor(self, didFailedAuthorizationWithModel: nil)
                completion?(nil, error)
                return
            }

            let isAnonymousAuthorization = registrationResult.authorizationType == .anonymous
            let newStep: SenderAuthorizationStep = isAnonymousAuthorization ? .phone : .success
            registrationResult.step = newStep
            self.currentStep = registrationResult.step
            completion?(registrationStatusModel, error)
            self.delegate?.senderAuthorizationInteractor(self, didPerformedRegistrationWith: registrationResult)
        }
    }

    public func deauthorizeWith(model: SenderDeauthorizationModel,
                                completion: SenderAuthorizationInteractorProtocol.DeauthorizationCompletion?) {
        self.server.sendDeauthorizationRequestWith(model: model) { error in
            if let error = error {
                self.delegate?.senderAuthorizationInteractor(self, didFailedDeauthorizationWithError: error)
            } else {
                self.delegate?.senderAuthorizationInteractorDidFinishedDeauthorization(self)
            }
        }
    }

    public func startEnteringNameWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        let nameStepModel = SenderAuthorizationStepModel(step: .name)
        self.handleStepResultWithModel(stepModel: nameStepModel, error: nil, completion: completion)
    }

    public func sendPhone(_ phone: String,
                          completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        self.server.sendPhone(phone) { (stepModel, error) in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func sendOTP(_ otp: String,
                        completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        guard self.currentStep == .OTP else { return }

        self.server.sendOTP(otp) { (stepModel, error) in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func startWaitingForConfirmWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        guard self.currentStep == .confirm else { return }

        self.server.startWaitingForConfirmWith { stepModel, error in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func stopWaitingForConfirm() {
        self.server.stopWaitingForConfirm()
    }

    public func cancelWaitingForConfirmWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        guard self.currentStep == .confirm else { return }

        self.server.cancelWaitingForConfirmWith { stepModel, error in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func requestIVRConfirmationWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        self.server.requestIVRConfirmationWith { stepModel, error in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func startWaitingForIVRWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        guard self.currentStep == .IVR else { return }

        self.server.startWaitingForIVRWith { stepModel, error in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func stopWaitingForIVR() {
        self.server.stopWaitingForIVR()
    }

    public func cancelWaitingForIVRWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        guard self.currentStep == .IVR else { return }

        self.server.cancelWaitingForIVRWith { stepModel, error in
            self.handleStepResultWithModel(stepModel: stepModel, error: error, completion: completion)
        }
    }

    public func sendName(_ name: String,
                         completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        self.server.sendName(name) { response, error in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            let stepModel = SenderAuthorizationStepModel(step: .photo)
            stepModel.additionalData = response as? [String: Any]
            stepModel.error = error
            self.currentStep = stepModel.step
            completion?(stepModel, nil)
            self.makeCallToDelegateIfNecessaryWith(stepModel: stepModel)
        }
    }

    public func sendPhoto(_ photoData: Data?,
                          completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        self.server.sendPhoto(photoData) { response, error in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            let stepModel = SenderAuthorizationStepModel(step: .userInfo)
            stepModel.additionalData = response as? [String: Any]
            stepModel.error = error
            self.currentStep = stepModel.step
            completion?(stepModel, nil)
            self.makeCallToDelegateIfNecessaryWith(stepModel: stepModel)
        }
    }

    public func loadUserInfo(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        self.server.loadUserInfo { response, error in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            if let userInfo = response { self.dataManager.saveUserInfo(userInfo) }
            let stepModel = SenderAuthorizationStepModel(step: .success)
            stepModel.additionalData = response as? [String: Any]
            stepModel.error = error
            self.currentStep = stepModel.step
            completion?(stepModel, nil)
            self.makeCallToDelegateIfNecessaryWith(stepModel: stepModel)
        }
    }

    fileprivate func handleStepResultWithModel(stepModel: SenderAuthorizationStepModel?,
                                               error: Error?,
                                               completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?) {
        let fixedStepModel = self.fixStateFor(stepModel: stepModel)
        let fixedStepModelNotNil = (fixedStepModel != nil)
        if fixedStepModelNotNil { self.currentStep = fixedStepModel!.step }
        completion?(fixedStepModel, error)
        if fixedStepModelNotNil { self.makeCallToDelegateIfNecessaryWith(stepModel: fixedStepModel!) }
    }

    fileprivate func fixStateFor(stepModel: SenderAuthorizationStepModel?) -> SenderAuthorizationStepModel? {
        guard let stepModelUnwrapped = stepModel, stepModelUnwrapped.step == .success else { return stepModel }

        if let firstReg = stepModelUnwrapped.additionalData?["firstReg"] as? String,
           let firstRegBool = Bool(firstReg), firstRegBool {
            stepModelUnwrapped.step = .name
        } else {
            stepModelUnwrapped.step = .userInfo
        }
        return stepModelUnwrapped
    }

    fileprivate func makeCallToDelegateIfNecessaryWith(stepModel: SenderAuthorizationStepModel) {
        if self.currentStep == .failure {
            self.delegate?.senderAuthorizationInteractor(self, didFailedAuthorizationWithModel: stepModel)
        } else if self.currentStep == .success {
            if stepModel.additionalData != nil {
                stepModel.additionalData!["isSenderAuthorization"] = true
            } else {
                stepModel.additionalData = ["isSenderAuthorization": true]
            }
            self.delegate?.senderAuthorizationInteractor(self, didFinishedAuthorizationWithModel: stepModel)
        } else if self.currentStep == .name {
            self.delegate?.senderAuthorizationInteractor(self, didAuthorizedAsNewUserWithModel: stepModel)
        }
    }
}
