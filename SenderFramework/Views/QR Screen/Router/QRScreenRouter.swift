//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScreenRouter: QRScreenRouterProtocol {
    weak var presenter: QRScreenPresenterProtocol?

    var qrScannerModule: ChildQRScannerModuleProtocol
    var qrDisplayModule: ChildQRDisplayModuleProtocol

    private weak var currentQRScreenView: QRScreenViewController?
    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?
    private var currentWireframe: ViewControllerWireframe?

    var qrString: String!

    init(qrScannerModule: ChildQRScannerModuleProtocol, qrDisplayModule: ChildQRDisplayModuleProtocol) {
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
    }

    var qrScreenView: QRScreenViewController {
        if let existingView = self.currentQRScreenView {
            return existingView
        } else {
            let newView = self.buildQRScreenView()
            self.currentQRScreenView = newView
            return newView
        }
    }

    func buildQRScreenView() -> QRScreenViewController {
        return QRScreenViewController.loadFromSenderFrameworkStoryboardWith(name: "QRScreenViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: QRScreenModuleDelegate?, qrString: String)
                    -> QRScreenViewController {
        let qrScreenView = self.qrScreenView
        qrScreenView.presenter = self.presenter
        self.presenter?.view = qrScreenView
        self.presenter?.delegate = moduleDelegate
        self.qrString = qrString
        return qrScreenView
    }

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           qrString: String,
                                                           forDelegate delegate: QRScreenModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.currentQRScreenView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let containerView = getViewAndPrepareForPresentationWith(moduleDelegate: delegate, qrString: qrString)
        wireframe.presentView(containerView, completion: completion)
        self.currentGenericWireframe = AnyWireframeWithAnyRootView(wireframe)
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         qrString: String,
                         forDelegate delegate: QRScreenModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentQRScreenView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let containerView = getViewAndPrepareForPresentationWith(moduleDelegate: delegate, qrString: qrString)
        wireframe.presentView(containerView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentQRScreenView else { return }
        self.currentGenericWireframe?.dismissView(currentView, completion: completion)
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func presentChildViews() {
        guard let containerView = self.currentQRScreenView else { return }

        let scannerWireframe = AddToContainerWireframe(rootView: containerView)
        let displayWireframe = AddToContainerWireframe(rootView: containerView)

        self.qrScannerModule.presentWith(wireframe: scannerWireframe, forDelegate: self.presenter, completion: nil)
        self.qrDisplayModule.presentWith(wireframe: displayWireframe,
                                         qrString: self.qrString,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }

    func showQRScanner() {
        let scannerWireframe = AddToContainerWireframe(rootView: qrScreenView)
        self.qrScannerModule.presentWith(wireframe: scannerWireframe, forDelegate: self.presenter, completion: nil)

    }

    func showQRImage() {
        let displayWireframe = AddToContainerWireframe(rootView: qrScreenView)
        self.qrDisplayModule.presentWith(wireframe: displayWireframe,
                                         qrString: self.qrString,
                                         forDelegate: self.presenter,
                                         completion: nil)
    }
}
