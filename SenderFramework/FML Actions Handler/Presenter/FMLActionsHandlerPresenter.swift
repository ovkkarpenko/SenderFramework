//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import GoogleSignIn

extension MWGoogleUser {
    convenience init(gidUser: GIDGoogleUser) {
        self.init(accessToken: gidUser.authentication.accessToken,
                  userID: gidUser.userID,
                  idToken: gidUser.authentication.idToken,
                  fullName: gidUser.profile.name,
                  givenName: gidUser.profile.givenName,
                  familyName: gidUser.profile.familyName,
                  email: gidUser.profile.email)
    }
}

class FMLActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol {
    weak var view: FMLActionsHandlerViewProtocol?
    var interactor: FMLActionsHandlerInteractorProtocol
    var router: FMLActionsHandlerRouterProtocol?

    var photoTakeCompletion: ((String?, UIKit.UIImage?) -> Void)?
    var locationGetCompletion: ((CLLocation, UIKit.UIImage?, String?) -> Void)?
    var entityPickerCompletion: (([Contact]) -> Void)?
    var qrScannerCompletion: ((String?) -> Void)?
    var termsConditionsCompletion: ((Bool) -> Void)?
    var googleSignInCompletion: ((MWGoogleUser?, Error?) -> Void)?
    var valueSelectCompletion: ((Any?) -> Void)?

    init(interactor: FMLActionsHandlerInteractorProtocol, router: FMLActionsHandlerRouterProtocol?) {
        self.interactor = interactor
        self.router = router
    }

    func handleFMLAction(_ action: [AnyHashable: Any], forForm form: PBConsoleView, actionField: PBSubviewFacade) {
        self.interactor.handleFMLAction(action, forForm: form, actionField: actionField)
    }

    func sendForm(_ form: PBConsoleView, withAction action: [AnyHashable: Any], actionField: PBSubviewFacade) {
        self.interactor.sendForm(form, withAction: action, actionField: actionField)
    }

    func loadFileForForm(_ form: PBConsoleView, actionField: PBLoadFileView) {
        self.interactor.loadFileForForm(form, actionField: actionField)
    }

    func getLocationForForm(_ form: PBConsoleView, actionField: PBMapView) {
        self.interactor.getLocationForForm(form, actionField: actionField)
    }

    func selectFromValues(_ values: [Any]?, forForm form: PBConsoleView, actionField: PBSelectedView) {
        self.interactor.selectFromValues(values, forForm: form, actionField: actionField)
    }

    func showQRScanner(completion: @escaping (String?) -> Void) {
        self.qrScannerCompletion = completion
        self.router?.presentQRScanner()
    }

    func takePhoto(completion: @escaping (String?, UIImage?) -> Void) {
        self.photoTakeCompletion = completion
        self.view?.showMediaPickerFor(mediaType: .photo)
    }

    func getLocation(completion: @escaping (CLLocation, UIImage?, String?) -> Void) {
        self.locationGetCompletion = completion
        self.view?.showMediaPickerFor(mediaType: .location)
    }

    func sendImageWith(assetID: String?, image: UIKit.UIImage?) {
        self.photoTakeCompletion?(assetID, image)
    }

    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?) {
        self.locationGetCompletion?(location, image, description)
    }

    func getGoogleUser(completion: @escaping (MWGoogleUser?, Error?) -> Void) {
        self.googleSignInCompletion = completion
        self.view?.showGoogleSignInScreen()
    }

    func selectFromValues(_ values: [Any], completion: @escaping (Any?) -> Void) {
        self.valueSelectCompletion = completion
        self.view?.showValuesSelectorWith(values: values)
    }

    func selectFrom(contacts: [Contact], allowsMultipleSelection: Bool, completion: @escaping ([Contact]) -> Void) {
        let entityModels = contacts.flatMap { ContactViewModel(contact: $0) }
        self.entityPickerCompletion = completion
        self.router?.showEntityPickerWith(entityModels: entityModels, allowsMultipleSelection: allowsMultipleSelection)
    }

    func showTermsAndConditions(completion: @escaping (Bool) -> Void) {
        self.termsConditionsCompletion = completion
        self.router?.showTermsAndConditions()
    }

    func showQRCodeWith(string: String) {
        self.router?.presentQRCodeWith(string: string)
    }

    func selectValueFromSelector(value: Any?) {
        self.valueSelectCompletion?(value)
        self.valueSelectCompletion = nil
    }

    func showFullVersionError(_ error: Error) {
        let errorText: String
        switch (error as NSError).code {
        case 1: errorText = SenderFrameworkLocalizedString("full_version_already_on")
        case 2: errorText = SenderFrameworkLocalizedString("full_version_already_off")
        default: errorText = SenderFrameworkLocalizedString("full_version_change_unknown_error")
        }
        self.view?.showErrorWithText(errorText)
    }

    func shareItems(_ items: [Any]) {
        self.view?.showShareScreenWith(items: items)
    }

    func showBitcoinSendingError(_ error: Error) {
        let errorText = SenderFrameworkLocalizedString("bitcoin_sending_error")
        DispatchQueue.main.async { self.view?.showErrorWithText(errorText) }
    }

    func showGoogleSignInError(_ error: Error) {
        self.view?.showErrorWithText(error.localizedDescription)
    }

    func googleSignInWith(user: GoogleSignIn.GIDGoogleUser?, error: Error?) {
        defer {
            self.googleSignInCompletion = nil
        }
        guard let user = user else { self.googleSignInCompletion?(nil, error); return }
        let googleUser = MWGoogleUser(gidUser: user)
        self.googleSignInCompletion?(googleUser, error)
    }

    func textWasCopiedToClipboard() {
        let infoText = SenderFrameworkLocalizedString("fml_text_was_copied")
        self.view?.showInfoWithText(infoText)
    }

    func interactorWillChangeFullVersionState() {
        self.view?.showActivityIndicator()
    }

    func interactorDidChangeFullVersionState() {
        self.view?.hideActivityIndicator()
    }
}

extension FMLActionsHandlerPresenter {
    func qrScannerModuleDidCancel() {
        self.qrScannerCompletion?(nil)
        self.router?.dismissQRScanner()
        self.qrScannerCompletion = nil
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.qrScannerCompletion?(string)
        self.router?.dismissQRScanner()
        self.qrScannerCompletion = nil
    }
}

extension FMLActionsHandlerPresenter {
    func qrDisplayModuleDidCancel() {
        self.router?.dismissQRCode()
    }
}

extension FMLActionsHandlerPresenter {
    func termsConditionsModuleDidAccept() {
        self.router?.dismissTermsAndConditions {
            self.termsConditionsCompletion?(true)
            self.termsConditionsCompletion = nil
        }
    }

    func termsConditionsModuleDidDecline() {
        self.router?.dismissTermsAndConditions {
            self.termsConditionsCompletion?(false)
            self.termsConditionsCompletion = nil
        }
    }
}

extension FMLActionsHandlerPresenter {
    func entityPickerModuleDidCancel() {
        self.entityPickerCompletion?([])
        self.router?.dismissEntityPicker()
        self.entityPickerCompletion = nil
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        let contacts = entities.flatMap { ($0 as? ContactViewModel)?.contact }
        self.entityPickerCompletion?(contacts)
        self.router?.dismissEntityPicker()
        self.entityPickerCompletion = nil
    }
}
