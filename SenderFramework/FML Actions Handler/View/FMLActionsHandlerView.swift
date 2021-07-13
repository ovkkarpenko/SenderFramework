//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import GoogleSignIn

class FMLActionsHandlerView: NSObject, FMLActionsHandlerViewProtocol {
    weak var viewController: UIViewController?
    var presenter: FMLActionsHandlerPresenterProtocol?
    var activityIndicator: UIActivityIndicatorView?

    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }

    // MARK: - Media Pickers

    func checkCameraAccess() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let viewController = self.viewController {
                let alert = UIAlertController(title: SenderFrameworkLocalizedString("error_ios"),
                                              message: SenderFrameworkLocalizedString("device_without_camera_ios"),
                                              preferredStyle: .alert)
                let okAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                             style: .cancel,
                                             handler: nil)
                alert.addAction(okAction)
                alert.mw_safePresentIn(viewController: viewController, animated: true, completion: nil)
            }
            return false
        }
        return true
    }

    func showMediaPickerFor(mediaType: FMLActionMediaType) {
        switch mediaType {
        case .photo: if self.checkCameraAccess() { self.showPhotoPicker() }
        case .location: self.showLocationPicker()
        }
    }

    var cameraManager: CameraManager?

    func showPhotoPicker() {
        guard let viewController = self.viewController else { return }

        self.cameraManager = CameraManager(parentController: viewController, chat: nil)
        self.cameraManager?.delegate = self
        self.cameraManager?.showCamera()
    }

    func showLocationPicker() {
        let mapController = ShowMapViewController()
        mapController.delegate = self
        self.viewController?.present(mapController, animated: true)
    }

    func showInfoWithText(_ infoText: String) {
        guard let viewController = self.viewController else { return }
        func showInfoWithText(_ infoText: String) {
            let alert = UIAlertController(title: nil,
                                          message: infoText,
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            alert.mw_safePresentIn(viewController: viewController, animated: true)
        }
    }

    func showErrorWithText(_ errorText: String) {
        guard let viewController = self.viewController else { return }

        let alert = UIAlertController(title: SenderFrameworkLocalizedString("error_ios"),
                                      message: errorText,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: viewController, animated: true)
    }

    func showShareScreenWith(items: [Any]) {
        guard let viewController = self.viewController else { return }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.mw_safePresentIn(viewController: viewController, animated: true)
    }

    func showGoogleSignInScreen() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }

    func showValuesSelectorWith(values: [Any]) {
        guard let viewController = self.viewController else { return }

        let popUpSelector = PBPopUpSelector(frame: UIScreen.main.bounds, andValues: values)
        popUpSelector.setupTableView()
        popUpSelector.delegate = self
        popUpSelector.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(popUpSelector)
        viewController.view.mw_pinSubview(popUpSelector)
    }

    func showActivityIndicator() {
        guard let viewController = self.viewController else { return }

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = SenderCore.shared().stylePalette.lineColor
        activityIndicator.startAnimating()
        viewController.view.addSubview(activityIndicator)
        activityIndicator.frame = CGRect(x: (viewController.view.frame.width - activityIndicator.frame.width) / 2,
                                         y: (viewController.view.frame.height - activityIndicator.frame.height) / 2,
                                         width: activityIndicator.frame.width,
                                         height: activityIndicator.frame.height)
        viewController.view.isUserInteractionEnabled = false
        self.activityIndicator = activityIndicator
    }

    func hideActivityIndicator() {
        guard let viewController = self.viewController else { return }

        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        viewController.view.isUserInteractionEnabled = true
        self.activityIndicator = nil
    }
}

extension FMLActionsHandlerView: CameraManagerDelegate {
    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPicking image: UIImage?,
                       withAssetID assetID: String?) {
        self.viewController?.dismiss(animated: true)
        self.cameraManager = nil
        self.presenter?.sendImageWith(assetID: assetID, image: image)
    }

    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPickingVideoWithAssetID assetID: String!,
                       duration: TimeInterval) {
        self.viewController?.dismiss(animated: true)
        self.cameraManager = nil
    }

    func cameraManagerDidFinishWithError(_ error: Error!) {
        self.viewController?.dismiss(animated: true)
        self.cameraManager = nil
    }
}

extension FMLActionsHandlerView: ShowMapViewControllerDelegate {
    func showMapViewController(_ controller: ShowMapViewController!,
                               didFinishEntering location: CLLocation!,
                               with image: UIImage!,
                               description: String!) {
        self.viewController?.dismiss(animated: true)
        guard let location = location else { return }
        self.presenter?.sendLocation(location, withImage: image, description: description)
    }
}

extension FMLActionsHandlerView: PBPopUpSelectorDelegate {
    func popUpSelector(_ popUpSelector: PBPopUpSelector!, didSelectValue value: Any!) {
        self.presenter?.selectValueFromSelector(value: value)
        popUpSelector.removeFromSuperview()
    }

    func popUpSelectorDidCancel(_ popUpSelector: PBPopUpSelector!) {
        self.presenter?.selectValueFromSelector(value: nil)
        popUpSelector.removeFromSuperview()
    }
}

extension FMLActionsHandlerView: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        self.presenter?.googleSignInWith(user: user, error: error)
    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.viewController?.present(viewController, animated: true)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.viewController?.dismiss(animated: true)
    }
}

extension FMLActionsHandlerView {
    func handleAction(_ action: [AnyHashable: Any]!, for consoleView: PBConsoleView!, actionView: PBSubviewFacade!) {
        guard let action = action, let consoleView = consoleView, let actionView = actionView else { return }
        self.presenter?.handleFMLAction(action, forForm: consoleView, actionField: actionView)
    }

    func send(_ consoleView: PBConsoleView!, withAction action: [AnyHashable: Any]!, actionView: PBSubviewFacade!) {
        self.presenter?.sendForm(consoleView, withAction: action, actionField: actionView)
    }

    func ownerViewController() -> UIViewController! {
        guard let viewController = self.viewController else {
            fatalError("FMLActionsHandlerView's viewController is nil. But PBConsoleView asked for ownerViewController")
        }
        return viewController
    }

    func loadFile(for fileView: PBLoadFileView!, in consoleView: PBConsoleView!) {
        self.presenter?.loadFileForForm(consoleView, actionField: fileView)
    }

    func getLocationFor(_ mapView: PBMapView!, in consoleView: PBConsoleView!) {
        self.presenter?.getLocationForForm(consoleView, actionField: mapView)
    }

    func select(fromValues values: [Any]!, forSelect selectView: PBSelectedView!, in consoleView: PBConsoleView!) {
        self.presenter?.selectFromValues(values, forForm: consoleView, actionField: selectView)
    }
}
