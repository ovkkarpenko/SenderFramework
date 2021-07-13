//
// Created by Roman Serga on 31/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderFullAuthorizationPresenter)
public class SenderFullAuthorizationPresenter: NSObject,
                                               SenderFullAuthorizationPresenterProtocol,
                                               SenderAuthorizationInteractorDelegate {

    public var interactor: SenderFullAuthorizationInteractorProtocol
    public var router: SenderFullAuthorizationRouterProtocol

    public weak var delegate: SenderAuthorizationModuleDelegate?
    public weak var eventHandler: SenderFullAuthorizationPresenterEventHandler?

    public init(authorizationManager: SenderFullAuthorizationInteractorProtocol,
                router: SenderFullAuthorizationRouterProtocol) {
        self.interactor = authorizationManager
        self.router = router
        super.init()
        self.router.presenter = self
        self.interactor.delegate = self
    }

    public func startAuthorizationWith(model: SenderAuthorizationModel) {
        self.router.showStartScreen()
        self.interactor.startAuthorizationWith(model: model) { model, error in
            self.handle(stepModel: model, error: error)
        }
    }

    public func deauthorizeWith(model: SenderDeauthorizationModel) {
        self.router.showDeauthorizationScreen()
        self.interactor.deauthorizeWith(model: model, completion: nil)
    }

    public func startEnteringNameWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.startEnteringNameWith { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func sendPhone(_ phone: String,
                          completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.sendPhone(phone) { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func sendOTP(_ otp: String,
                        completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.sendOTP(otp) { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func startWaitingForConfirmWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.startWaitingForConfirmWith { stepModel, error in
            self.handle(stepModel: stepModel, error: error)
            completion?(stepModel, error)
        }
    }

    public func stopWaitingForConfirm() {
        self.interactor.stopWaitingForConfirm()
    }

    public func cancelWaitingForConfirmWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.cancelWaitingForConfirmWith { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func requestIVRConfirmationWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.requestIVRConfirmationWith { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func startWaitingForIVRWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.startWaitingForIVRWith { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func stopWaitingForIVR() {
        self.interactor.stopWaitingForIVR()
    }

    public func cancelWaitingForIVRWith(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.cancelWaitingForIVRWith { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func loadUserInfo(completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.loadUserInfo { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func sendName(_ name: String,
                         completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.sendName(name) { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    public func sendPhoto(_ photoData: Data?,
                          completion: SenderFullAuthorizationPresenterProtocol.AuthorizationStepCompletion?) {
        self.interactor.sendPhoto(photoData) { stepModel, error in
            completion?(stepModel, error)
            self.handle(stepModel: stepModel, error: error)
        }
    }

    private func handle(stepModel: SenderAuthorizationStepModel?, error: Error?) {
        guard error == nil else {
            self.router.showError(error!, completion: nil)
            return
        }

        guard let stepModel = stepModel else {
            let error = NSError(domain: "Both stepModel and error are nil", code: 666)
            self.router.showError(error, completion: nil)
            return
        }

        if let error = stepModel.error {
            self.router.showError(error) { _ in
                self.showScreenFor(stepModel: stepModel)
            }
        } else {
            self.showScreenFor(stepModel: stepModel)
        }
    }

    private func showScreenFor(stepModel: SenderAuthorizationStepModel) {
        if stepModel.step != .IVR { self.stopWaitingForIVR() }
        if stepModel.step != .confirm { self.stopWaitingForConfirm() }

        switch stepModel.step {
        case .none:
            return
        case .initialization:
            self.router.showStartScreen()
        case .phone:
            self.router.showPhoneEnterScreen()
        case .OTP:
            self.router.showOTPScreenWithModel(stepModel)
        case .IVR:
            self.startWaitingForIVRWith { stepModel, error in
                self.eventHandler?.senderAuthorizationPresenter?(self, didReceiveConfirmModel: stepModel, error: error)
            }
            self.router.showIVRScreenWithModel(stepModel)
        case .confirm:
            self.startWaitingForConfirmWith { stepModel, error in
                self.eventHandler?.senderAuthorizationPresenter?(self, didReceiveConfirmModel: stepModel, error: error)
            }
            self.router.showConfirmScreenWithModel(stepModel)
        case .name:
            self.router.showNameEnterScreenWithModel(stepModel)
        case .photo:
            self.router.showPhotoAddScreenWithModel(stepModel)
        case .success:
            self.router.showSuccessScreenWithModel(stepModel)
        case .failure:
            self.router.showFailureScreenWithModel(stepModel)
        case .userInfo:
            self.router.showSuccessScreenWithModel(stepModel)
            self.loadUserInfo(completion: nil)
        }
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
