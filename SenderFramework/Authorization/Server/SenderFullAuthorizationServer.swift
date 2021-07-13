//
// Created by Roman Serga on 30/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc (MWSenderAuthorizationServer)
public class SenderFullAuthorizationServer: NSObject,
                                            SenderFullAuthorizationServerProtocol,
                                            MWCometParserAuthorizationHandler {

    private var confirmCompletion: ((SenderAuthorizationStepModel?, Error?) -> Void)?
    private var ivrCompletion: ((SenderAuthorizationStepModel?, Error?) -> Void)?

    private var isCometActive = false

    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(senderCoreDidChangeIsPaused(notification:)),
                                               name: Notification.Name(rawValue: SenderCoreDidChangeIsPausedState),
                                               object: SenderCore.shared())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground(notification:)),
                                               name: .UIApplicationDidEnterBackground,
                                               object: SenderCore.shared().application)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive(notification:)),
                                               name: .UIApplicationDidBecomeActive,
                                               object: SenderCore.shared().application)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func sendAuthorizationRequestWith(model: SenderAuthorizationModel,
                                             completion: ((SenderRegistrationModel?, Error?) -> Void)?) {

        var additionalParams = [String: Any]()
        if let deviceIMEI = model.deviceIMEI { additionalParams["imei"] = deviceIMEI }
        if let companyID = model.companyID { additionalParams["companyId"] = companyID }
        if let authToken = model.authToken { additionalParams["authToken"] = authToken }

        ServerFacade.sharedInstance().registrationRequest(withUDID: model.deviceUDID,
                                                          developerID: model.developerID,
                                                          additionalParameters: additionalParams) { (response, error) in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            guard let response = response else {
                let error = NSError(domain: "Cannot get response", code: 666)
                completion?(nil, error)
                return
            }

            guard let deviceKey = response["deviceKey"] as? String,
                  let authString = response["auth"] as? String,
                  let authorizationType = self.authorizationTypeFrom(authString: authString) else {
                let error = NSError(domain: "Wrong response", code: 666)
                completion?(nil, error)
                return
            }

            let applicationModeString = response["mode"] as? String
            let applicationMode = self.applicationModeFrom(modeString: applicationModeString)
            let registrationModel = SenderRegistrationModel(deviceKey: deviceKey,
                                                            authorizationType: authorizationType,
                                                            applicationMode: applicationMode)
            completion?(registrationModel, nil)
        }
    }

    public func sendDeauthorizationRequestWith(model: SenderDeauthorizationModel,
                                               completion: SenderAuthorizationInteractorProtocol.DeauthorizationCompletion?) {
        var additionalParams = [String: Any]()
        if let deviceIMEI = model.deviceIMEI { additionalParams["imei"] = deviceIMEI }
        if let companyID = model.companyID { additionalParams["companyId"] = companyID }

        ServerFacade.sharedInstance().unlinkRequest(withUDID: model.deviceUDID,
                                                    developerID: model.developerID,
                                                    additionalParameters: additionalParams) { (response, error) in
            guard error == nil else {
                completion?(error)
                return
            }

            guard response != nil else {
                let error = NSError(domain: "Cannot get response", code: 666)
                completion?(error)
                return
            }

            completion?(nil)
        }
    }

    fileprivate func authorizationTypeFrom(authString: String) -> SenderAuthorizationType? {
        switch authString {
        case "auth":
            return .auth
        case "anonymous":
            return .anonymous
        case "sso":
            return .sso
        default:
            return nil
        }
    }

    fileprivate func applicationModeFrom(modeString: String?) -> SenderApplicationMode {
        if let mode = modeString, mode == "full" {
            return .full
        } else {
            return .restricted
        }
    }

    fileprivate func authorizationStepFrom(responseString: String) -> SenderAuthorizationStep? {
        switch responseString {
        case "otp":
            return .OTP
        case "success":
            return .success
        case "phone":
            return .phone
        case "ivr":
            return .IVR
        case "confirm":
            return .confirm
        default:
            return nil
        }
    }

    public func sendPhone(_ phone: String, completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendPhone(forAuthRequest: phone) { (response, error) in
            let parsedResult = self.handleStepResponse(response, error: error)
            completion?(parsedResult.model, parsedResult.error)
        }
    }

    fileprivate func stepErrorFrom(responseDictionary: [AnyHashable: Any]) -> Error? {
        guard let errorString = responseDictionary["error"] as? String else { return nil }
        let errorCodeParsed = AuthErrorCodesParser.parseErrorCode(errorString)
        return NSError(domain: errorCodeParsed, code: 666)
    }

    fileprivate func handleStepResponse(_ response: [AnyHashable: Any]?,
                                        error: Error?) -> (model: SenderAuthorizationStepModel?, error: Error?) {
        guard error == nil else {
            return (nil, error)
        }

        guard let response = response else {
            let error = NSError(domain: "Cannot get response", code: 666)
            return (nil, error)
        }

        guard let stepString = response["step"] as? String,
              let step = self.authorizationStepFrom(responseString: stepString) else {
            let error = NSError(domain: "Wrong response", code: 666)
            return (nil, error)
        }

        let stepError = self.stepErrorFrom(responseDictionary: response)

        let stepModel = SenderAuthorizationStepModel(step: step)
        stepModel.error = stepError
        stepModel.additionalData = response as? [String: Any]
        return (stepModel, nil)
    }

    public func sendOTP(_ otp: String, completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendOtp(forAuthRequest: otp) { (response, error) in
            let parsedResult = self.handleStepResponse(response, error: error)
            completion?(parsedResult.model, parsedResult.error)
        }
    }

    public func startWaitingForConfirmWith(completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        //TODO: Add timeout
        if SenderCore.shared().isPaused { CometController.sharedInstance().isPaused = false }
        self.isCometActive = true
        self.confirmCompletion = completion
        MWCometParser.shared.authorizationHandler = self
    }

    public func stopWaitingForConfirm() {
        if SenderCore.shared().isPaused { CometController.sharedInstance().isPaused = true }
        self.isCometActive = false
        self.confirmCompletion = nil
    }

    public func cancelWaitingForConfirmWith(completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().cancelWaitRequest { (response, error) in
            self.stopWaitingForConfirm()
            let parsedResult = self.handleStepResponse(response, error: error)
            completion?(parsedResult.model, parsedResult.error)
        }
    }

    public func requestIVRConfirmationWith(completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().askFroIVR { response, error in
            let parsedResult = self.handleStepResponse(response, error: error)
            completion?(parsedResult.model, parsedResult.error)
        }
    }

    public func startWaitingForIVRWith(completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        //TODO: Add timeout
        if SenderCore.shared().isPaused { CometController.sharedInstance().isPaused = false }
        self.isCometActive = true
        self.ivrCompletion = completion
        MWCometParser.shared.authorizationHandler = self
    }

    public func stopWaitingForIVR() {
        if SenderCore.shared().isPaused { CometController.sharedInstance().isPaused = true }
        self.isCometActive = false
        self.ivrCompletion = nil
    }

    public func cancelWaitingForIVRWith(completion: ((SenderAuthorizationStepModel?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().cancelWaitRequest { (response, error) in
            self.stopWaitingForIVR()
            let parsedResult = self.handleStepResponse(response, error: error)
            completion?(parsedResult.model, parsedResult.error)
        }
    }

    public func sendName(_ name: String, completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().setSelfInfo(["name": name], withRequestHandler: completion)
    }

    public func sendPhoto(_ photoData: Data?, completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        guard let photoData = photoData else {
            ServerFacade.sharedInstance().setSelfInfo(["photo": ""], withRequestHandler: completion)
            return
        }

        ServerFacade.sharedInstance().uploadData(photoData,
                                                 withFileExtension: "jpg",
                                                 target: "user_logo",
                                                 additionalData: nil) { (response, error) in
            guard error == nil else {
                completion?(nil, error)
                return
            }

            guard let photoURL = response?["url"] as? String else {
                let error = NSError(domain: "Cannot get photo URL from response", code: 666)
                completion?(nil, error)
                return
            }

            ServerFacade.sharedInstance().setSelfInfo(["photo": photoURL], withRequestHandler: completion)
        }
    }

    public func loadUserInfo(completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().getSelfInfo { response, error in
            let selfInfo = response?["selfInfo"] as? [AnyHashable: Any]
            completion?(selfInfo, error)
        }
    }

    public func cometParser(_ parser: MWCometParser, didReceiveAuthorizationMessage message: [String: Any]) {
        defer {
            if MWCometParser.shared.authorizationHandler === self {
                MWCometParser.shared.authorizationHandler = nil
            }
            self.stopWaitingForConfirm()
            self.stopWaitingForIVR()
        }

        guard let model = message["model"] as? [String: Any] else {
            let error = NSError(domain: "Wrong response", code: 666)
            self.confirmCompletion?(nil, error)
            self.ivrCompletion?(nil, error)
            return
        }

        let parsedResult = self.handleStepResponse(model, error: nil)
        self.confirmCompletion?(parsedResult.model, parsedResult.error)
        self.ivrCompletion?(parsedResult.model, parsedResult.error)
    }

    @objc private func senderCoreDidChangeIsPaused(notification: Notification) {
        if SenderCore.shared().isPaused && self.isCometActive { CometController.sharedInstance().isPaused = false }
    }

    @objc private func applicationDidBecomeActive(notification: Notification) {
        if SenderCore.shared().isPaused && self.isCometActive { CometController.sharedInstance().isPaused = false }
    }

    @objc private func applicationDidEnterBackground(notification: Notification) {
        if SenderCore.shared().isPaused && self.isCometActive { CometController.sharedInstance().isPaused = true }
    }
}
