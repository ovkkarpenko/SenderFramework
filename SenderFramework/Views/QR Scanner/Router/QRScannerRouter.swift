//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class QRScannerRouter: QRScannerRouterProtocol {

    weak var presenter: QRScannerPresenterProtocol?

    fileprivate weak var currentQRScannerView: QRScannerViewController?
    private var currentWireframe: ViewControllerWireframe?

    var qrScannerView: QRScannerViewController {
        if let existingView = self.currentQRScannerView {
            return existingView
        } else {
            let newView = self.buildQRScannerView()
            self.currentQRScannerView = newView
            return newView
        }
    }

    func buildQRScannerView() -> QRScannerViewController {
        return QRScannerViewController.loadFromSenderFrameworkStoryboardWith(name: "QRScannerViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: QRScannerModuleDelegate?)
                    -> QRScannerViewController {
        let qrScannerView = self.qrScannerView
        qrScannerView.presenter = self.presenter
        self.presenter?.view = qrScannerView
        self.presenter?.delegate = moduleDelegate
        return qrScannerView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: QRScannerModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentQRScannerView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let qrScannerView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(qrScannerView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let scannerView = self.currentQRScannerView else { return }
        self.currentWireframe?.dismissView(scannerView, completion: completion)
    }
}

class ChildQRScannerRouter: QRScannerRouter, ChildQRScannerRouterProtocol {

    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: QRScannerModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        let qrScannerView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(qrScannerView, completion: completion)
        self.currentGenericWireframe = AnyWireframeWithAnyRootView(wireframe)
    }

    override func dismissView(completion: (() -> Void)?) {
        super.dismissView(completion: nil)
        guard let scannerView = self.currentQRScannerView else { return }
        self.currentGenericWireframe?.dismissView(scannerView, completion: completion)
    }
}