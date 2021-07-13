//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWFullSenderAuthorizationInteractorProtocol)
public protocol SenderFullAuthorizationInteractorProtocol: SenderAuthorizationInteractorProtocol {
    func startEnteringNameWith(completion: AuthorizationStepCompletion?)

    func sendPhone(_ phone: String, completion: AuthorizationStepCompletion?)
    func sendOTP(_ otp: String, completion: AuthorizationStepCompletion?)
    func startWaitingForConfirmWith(completion: AuthorizationStepCompletion?)
    func cancelWaitingForConfirmWith(completion: AuthorizationStepCompletion?)
    func stopWaitingForConfirm()
    func requestIVRConfirmationWith(completion: AuthorizationStepCompletion?)
    func startWaitingForIVRWith(completion: AuthorizationStepCompletion?)
    func stopWaitingForIVR()
    func cancelWaitingForIVRWith(completion: AuthorizationStepCompletion?)
    func sendName(_ name: String, completion: AuthorizationStepCompletion?)
    func sendPhoto(_ photoData: Data?, completion: AuthorizationStepCompletion?)
}

@objc(SenderFullAuthorizationPresenterProtocol)
public protocol SenderFullAuthorizationPresenterProtocol: SenderAuthorizationPresenterProtocol {
    typealias AuthorizationStepCompletion = (SenderAuthorizationStepModel?, Error?) -> Void

    weak var eventHandler: SenderFullAuthorizationPresenterEventHandler? { get set }

    func sendPhone(_ phone: String, completion: AuthorizationStepCompletion?)
    func sendOTP(_ otp: String, completion: AuthorizationStepCompletion?)
    func startWaitingForConfirmWith(completion: AuthorizationStepCompletion?)
    func stopWaitingForConfirm()
    func cancelWaitingForConfirmWith(completion: AuthorizationStepCompletion?)
    func requestIVRConfirmationWith(completion: AuthorizationStepCompletion?)
    func startWaitingForIVRWith(completion: AuthorizationStepCompletion?)
    func stopWaitingForIVR()
    func cancelWaitingForIVRWith(completion: AuthorizationStepCompletion?)
    func sendName(_ name: String, completion: AuthorizationStepCompletion?)
    func sendPhoto(_ photoData: Data?, completion: AuthorizationStepCompletion?)
    func loadUserInfo(completion: AuthorizationStepCompletion?)
}

/*
    We cannot currently use MWSenderFullAuthorizationRouterProtocol name because of bug
    that makes objective c property conforming to swift protocol with alternative name for objective-c
    invisible to swift files
*/
@objc(SenderFullAuthorizationRouterProtocol)
public protocol SenderFullAuthorizationRouterProtocol: SenderAuthorizationRouterProtocol {
    var presenter: SenderFullAuthorizationPresenterProtocol? { get set }

    func showPhoneEnterScreen()
    func showConfirmScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
    func showOTPScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
    func showIVRScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
    func showNameEnterScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
    func showPhotoAddScreenWithModel(_ stepModel: SenderAuthorizationStepModel)
}

@objc(MWSenderFullAuthorizationPresenterEventHandler)
public protocol SenderFullAuthorizationPresenterEventHandler: class {
    @objc optional func senderAuthorizationPresenter(_ authorizationPresenter: SenderFullAuthorizationPresenter,
                                                     didReceiveConfirmModel: SenderAuthorizationStepModel?,
                                                     error: Error?)
}

@objc(MWSenderFullAuthorizationServerProtocol)
public protocol SenderFullAuthorizationServerProtocol: SenderAuthorizationServerProtocol {
    func sendPhone(_ phone: String, completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func sendOTP(_ otp: String, completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func startWaitingForConfirmWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func stopWaitingForConfirm()
    func cancelWaitingForConfirmWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func requestIVRConfirmationWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func startWaitingForIVRWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)
    func stopWaitingForIVR()
    func cancelWaitingForIVRWith(completion: SenderFullAuthorizationInteractorProtocol.AuthorizationStepCompletion?)

    func sendName(_ name: String, completion: (([AnyHashable: Any]?, Error?) -> Void)?)
    func sendPhoto(_ photoData: Data?, completion: (([AnyHashable: Any]?, Error?) -> Void)?)
}

@objc(MWSenderFullAuthorizationModuleProtocol)
public protocol SenderFullAuthorizationModuleProtocol: SenderAuthorizationModuleProtocol {
    func startEnteringName()
}
