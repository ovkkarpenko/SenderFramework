//
// Created by Roman Serga on 31/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(MWSenderFullAuthorizationRouter)
public class SenderFullAuthorizationRouter: NSObject, SenderFullAuthorizationRouterProtocol {

    public var presenter: SenderFullAuthorizationPresenterProtocol?
    public var navigationController: UINavigationController

    let registrationStoryboard: UIStoryboard = {
        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        return UIStoryboard(name: "Registration", bundle: senderFrameworkBundle)
    }()

    private enum RegistrationControllerStoryboardID: String {
        case phoneControllerID = "EnterPhoneViewController"
        case confirmControllerID = "WaitForConfirmViewController"
        case termsConditionsNavControllerID = "TermsConditionsNavViewController"
        case termsConditionsControllerID = "TermsConditionsViewController"
        case OTPControllerID = "EnterOTPViewController"
        case IVRControllerID = "WaitForIVRViewController"
        case nameControllerID = "EnterNameViewController"
        case photoControllerID = "AddPhotoViewController"
    }

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    private func createRegistrationControllerWithID<ControllerType>(_ controllerID: RegistrationControllerStoryboardID,
                                                                    ofType type: ControllerType.Type) -> ControllerType {
        return self.registrationStoryboard.instantiateViewController(withIdentifier: controllerID.rawValue) as! ControllerType
    }

    private func registrationControllerWithID<ControllerType>(_ controllerID: RegistrationControllerStoryboardID,
                                                              ofType type: ControllerType.Type) -> ControllerType {
        let registrationController: ControllerType
        if let controller = self.controllerInStackOf(type: type) {
            registrationController = controller
        } else {
            registrationController = self.createRegistrationControllerWithID(controllerID, ofType: type)
        }
        return registrationController
    }

    private func controllerInStackOf<ControllerType>(type: ControllerType.Type) -> ControllerType? {
        let controllers = navigationController.viewControllers.flatMap { return $0 as? ControllerType }
        return controllers.first
    }

    func prepareRegistrationControllerForPresentation(_ controller: RegistrationViewController) {
        controller.presenter = self.presenter
        controller.isActive = true
        controller.clearScreen()
    }

    public func showRegistrationController(_ controller: RegistrationViewController) {
        self.prepareRegistrationControllerForPresentation(controller)
        self.pushViewController(controller)
    }

     public func pushViewController(_ controller: UIViewController) {
        if self.navigationController.presentedViewController != nil {
            self.navigationController.dismiss(animated: true) {
                self.pushViewController(controller)
            }
            return
        }
        if self.navigationController.viewControllers.contains(controller) {
            self.navigationController.popToViewController(controller, animated: true)
        } else {
            self.navigationController.pushViewController(controller, animated: true)
        }
    }

    public func setViewController(_ controller: UIViewController) {
        if self.navigationController.presentedViewController != nil {
            self.navigationController.dismiss(animated: true) {
                self.setViewController(controller)
            }
            return
        }
        self.navigationController.setViewControllers([controller], animated: true)
    }

    public func showStartScreen() {
        let welcomeController = self.getWelcomeController()
        self.setViewController(welcomeController)
    }

    public func showPhoneEnterScreen() {
        let phoneController = self.registrationControllerWithID(.phoneControllerID,
                                                                ofType: EnterPhoneViewController.self)
        self.showRegistrationController(phoneController)
    }

    public func showConfirmScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let confirmController = self.registrationControllerWithID(.confirmControllerID,
                                                                  ofType: WaitForConfirmViewController.self)
        confirmController.deviceName = (stepModel.additionalData?["devName"] as? String) ?? confirmController.deviceName
        self.showRegistrationController(confirmController)
    }

    public func showOTPScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let otpController = self.registrationControllerWithID(.OTPControllerID, ofType: EnterOTPViewController.self)
        if let incomingMessage = stepModel.additionalData {
            otpController.incomingMessage = incomingMessage
        }
        self.showRegistrationController(otpController)
    }

    public func showIVRScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let otpController = self.registrationControllerWithID(.IVRControllerID, ofType: WaitForIVRViewController.self)
        if let incomingMessage = stepModel.additionalData {
            otpController.incomingMessage = incomingMessage
        }
        self.showRegistrationController(otpController)
    }

    public func showNameEnterScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let nameController = self.registrationControllerWithID(.nameControllerID, ofType: EnterNameViewController.self)
        self.showRegistrationController(nameController)
    }

    public func showPhotoAddScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let photoController = self.registrationControllerWithID(.photoControllerID, ofType: AddPhotoViewController.self)
        self.showRegistrationController(photoController)
    }

    public func showSuccessScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let welcomeController = self.getWelcomeController()
        self.pushViewController(welcomeController)
    }

    public func showFailureScreenWithModel(_ stepModel: SenderAuthorizationStepModel) {
        let welcomeController = self.getWelcomeController()
        self.pushViewController(welcomeController)
    }

    public func showError(_ error: Error, completion: ((Bool) -> Void)?) {
        if let topRegistrationController = self.navigationController.topViewController as? RegistrationViewController {
            let convertedError = error as NSError
            topRegistrationController.showError(convertedError.domain) { completion?(true) }
        } else {
            completion?(true)
        }
    }

    public func showDeauthorizationScreen() {
        let welcomeController = self.getWelcomeController()
        self.setViewController(welcomeController)
    }

    fileprivate func getWelcomeController() -> WelcomeViewController {
        let welcomeController: WelcomeViewController
        if let controller = self.controllerInStackOf(type: WelcomeViewController.self) {
            welcomeController = controller
        } else {
            welcomeController = WelcomeViewController()
        }
        return welcomeController
    }

}
