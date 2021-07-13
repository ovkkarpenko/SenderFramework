//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol FMLActionsHandlerRouterDelegate: class {
    func fmlActionsHandlerRouterViewControllerForPresentation(_ fmlActionsHandlerRouter: FMLActionsHandlerRouter)
                    -> UIViewController?
}

class FMLActionsHandlerRouter: FMLActionsHandlerRouterProtocol {
    weak var presenter: FMLActionsHandlerPresenterProtocol?
    weak var delegate: FMLActionsHandlerRouterDelegate?

    var entityPickerModule: EntityPickerModuleProtocol
    var qrScannerModule: QRScannerModuleProtocol
    var qrDisplayModule: QRDisplayModule
    var termsConditionsModule: TermsConditionsModuleProtocol

    var viewControllerForPresentation: UIViewController? {
        return self.delegate?.fmlActionsHandlerRouterViewControllerForPresentation(self)
    }

    init(entityPickerModule: EntityPickerModuleProtocol,
         qrScannerModule: QRScannerModuleProtocol,
         qrDisplayModule: QRDisplayModule,
         termsConditionsModule: TermsConditionsModuleProtocol) {
        self.entityPickerModule = entityPickerModule
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
        self.termsConditionsModule = termsConditionsModule
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.dismissQRCode()
        self.dismissEntityPicker()
        self.dismissTermsAndConditions(completion: nil)
    }

    func showEntityPickerWith(entityModels: [EntityViewModel], allowsMultipleSelection: Bool) {
        guard let currentChatView = self.viewControllerForPresentation else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        self.entityPickerModule.presentWith(wireframe: wireframe,
                                            entityModels: entityModels,
                                            allowsMultipleSelection: allowsMultipleSelection,
                                            forDelegate: self.presenter,
                                            completion: nil)
    }

    func dismissEntityPicker() {
        self.entityPickerModule.dismiss(completion: nil)
    }

    func presentQRScanner() {
        guard let currentChatView = self.viewControllerForPresentation else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        wireframe.animatedPresentation = true
        self.qrScannerModule.presentWith(wireframe: wireframe,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissQRScanner() {
        self.qrScannerModule.dismiss(completion: nil)
    }

    func presentQRCodeWith(string: String) {
        guard let currentChatView = self.viewControllerForPresentation else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        wireframe.animatedPresentation = true
        self.qrDisplayModule.presentWith(wireframe: wireframe,
                                         qrString: string,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func dismissQRCode() {
        self.qrDisplayModule.dismiss(completion: nil)
    }

    func showTermsAndConditions() {
        guard let currentChatView = self.viewControllerForPresentation else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentChatView)
        self.termsConditionsModule.presentWith(wireframe: wireframe, forDelegate: self.presenter, completion: nil)
    }

    func dismissTermsAndConditions(completion: (() -> Void)?) {
        self.termsConditionsModule.dismiss(completion: completion)
    }
}
