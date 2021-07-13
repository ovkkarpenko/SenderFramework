//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class QRDisplayRouter: QRDisplayRouterProtocol {

    weak var presenter: QRDisplayPresenterProtocol?

    fileprivate weak var currentQRDisplayView: QRDisplayViewController?
    private var currentWireframe: ViewControllerWireframe?

    var qrDisplayView: QRDisplayViewController {
        if let existingView = self.currentQRDisplayView {
            return existingView
        } else {
            let newView = self.buildQRDisplayView()
            self.currentQRDisplayView = newView
            return newView
        }
    }

    func buildQRDisplayView() -> QRDisplayViewController {
        return QRDisplayViewController(nibName: "QRDisplayViewController", bundle: Bundle.senderFrameworkResources)
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: QRDisplayModuleDelegate?)
                    -> QRDisplayViewController {
        let qrDisplayView = self.qrDisplayView
        qrDisplayView.presenter = self.presenter
        self.presenter?.view = qrDisplayView
        self.presenter?.delegate = moduleDelegate
        return qrDisplayView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: QRDisplayModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentQRDisplayView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let qrDisplayView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(qrDisplayView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let scannerView = self.currentQRDisplayView else { return }
        self.currentWireframe?.dismissView(scannerView, completion: completion)
    }
}

class ChildQRDisplayRouter: QRDisplayRouter, ChildQRDisplayRouterProtocol {
    private var currentGenericWireframe: AnyWireframeWithAnyRootView<UIViewController>?

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: QRDisplayModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        let qrDisplayView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(qrDisplayView, completion: completion)
        self.currentGenericWireframe = AnyWireframeWithAnyRootView(wireframe)
    }

    override func dismissView(completion: (() -> Void)?) {
        super.dismissView(completion: nil)
        guard let scannerView = self.currentQRDisplayView else { return }
        self.currentGenericWireframe?.dismissView(scannerView, completion: completion)
    }
}