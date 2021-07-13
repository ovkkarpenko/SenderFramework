//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import GoogleSignIn

public enum FMLActionMediaType {
    case photo
    case location
}

public protocol FMLActionsHandlerViewProtocol: class, PBConsoleViewDelegate {
    var presenter: FMLActionsHandlerPresenterProtocol? { get set }

    func showMediaPickerFor(mediaType: FMLActionMediaType)
    func showInfoWithText(_ infoText: String)
    func showErrorWithText(_ errorText: String)
    func showShareScreenWith(items: [Any])
    func showGoogleSignInScreen()
    func showValuesSelectorWith(values: [Any])
    func showActivityIndicator()
    func hideActivityIndicator()
}

public protocol FMLActionsHandlerPresenterProtocol: class,
                                             QRScannerModuleDelegate,
                                             QRDisplayModuleDelegate,
                                             TermsConditionsModuleDelegate,
                                             EntityPickerModuleDelegate {
    weak var view: FMLActionsHandlerViewProtocol? { get set }
    var interactor: FMLActionsHandlerInteractorProtocol { get set }
    var router: FMLActionsHandlerRouterProtocol? { get set }

    //Handling form view
    func handleFMLAction(_ action: [AnyHashable: Any], forForm form: PBConsoleView, actionField: PBSubviewFacade)
    func sendForm(_ form: PBConsoleView, withAction action: [AnyHashable: Any], actionField: PBSubviewFacade)
    func loadFileForForm(_ form: PBConsoleView, actionField: PBLoadFileView)
    func getLocationForForm(_ form: PBConsoleView, actionField: PBMapView)
    func selectFromValues(_ values: [Any]?, forForm form: PBConsoleView, actionField: PBSelectedView)

    func sendImageWith(assetID: String?, image: UIKit.UIImage?)
    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?)

    //Handling form interactor
    func showQRScanner(completion: @escaping (String?) -> Void)
    func takePhoto(completion: @escaping (String?, UIKit.UIImage?) -> Void)
    func getLocation(completion: @escaping (CLLocation, UIKit.UIImage?, String?) -> Void)
    func getGoogleUser(completion: @escaping (MWGoogleUser?, Error?) -> Void)
    func selectFromValues(_ values: [Any], completion: @escaping (Any?) -> Void)
    func selectFrom(contacts: [Contact],
                    allowsMultipleSelection: Bool,
                    completion: @escaping ([Contact]) -> Void)
    func showTermsAndConditions(completion: @escaping (Bool) -> Void)
    func showQRCodeWith(string: String)
    func selectValueFromSelector(value: Any?)
    func showFullVersionError(_ error: Error)
    func shareItems(_ items: [Any])
    func showBitcoinSendingError(_ error: Error)
    func showGoogleSignInError(_ error: Error)
    func googleSignInWith(user: GIDGoogleUser?, error: Error?)
    func textWasCopiedToClipboard()
    func interactorWillChangeFullVersionState()
    func interactorDidChangeFullVersionState()
}

public protocol FMLActionsHandlerRouterProtocol: class {
    weak var presenter: FMLActionsHandlerPresenterProtocol? { get set }

    func showEntityPickerWith(entityModels: [EntityViewModel], allowsMultipleSelection: Bool)
    func dismissEntityPicker()

    func presentQRScanner()
    func dismissQRScanner()

    func presentQRCodeWith(string: String)
    func dismissQRCode()

    func showTermsAndConditions()
    func dismissTermsAndConditions(completion: (() -> Void)?)

    func dismissAllViews(completion: (() -> Void)?)
}

public protocol FMLActionsHandlerInteractorProtocol: class {
    var chat: Dialog! { get set }
    weak var presenter: FMLActionsHandlerPresenterProtocol? { get set }

    func handleFMLAction(_ action: [AnyHashable: Any], forForm form: PBConsoleView, actionField: PBSubviewFacade)
    func sendForm(_ form: PBConsoleView, withAction action: [AnyHashable: Any], actionField: PBSubviewFacade)
    func loadFileForForm(_ form: PBConsoleView, actionField: PBLoadFileView)
    func getLocationForForm(_ form: PBConsoleView, actionField: PBMapView)
    func selectFromValues(_ values: [Any]?, forForm form: PBConsoleView, actionField: PBSelectedView)
}

public protocol FMLActionsHandlerDataManagerProtocol {
    func uploadData(_ data: Data, completion: ((URL?, Error?) -> Void)?)
    func getSenderUsers() -> [Contact]
    func getContacts() -> [Contact]
    func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?)
    func sendFormData(_ formData: [AnyHashable: Any], completion: ((Bool, Error?) -> Void)?)
    func getOwnerBitcoinWallet() -> BitcoinWallet?
    func changeFullVersionStateTo(newFullVersionState: Bool, completion: ((Bool, Error?) -> Void)?)
    func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?)
}
