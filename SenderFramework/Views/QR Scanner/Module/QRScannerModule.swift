//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class QRScannerModule: NSObject, QRScannerModuleProtocol {

    fileprivate weak var router: QRScannerRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: QRScannerModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let qrScannerCameraManager = QRScannerCameraManager()
        let qRScannerInteractor = QRScannerInteractor(cameraManager: qrScannerCameraManager)
        let qrScannerRouter = QRScannerRouter()
        let qRScannerPresenter = QRScannerPresenter(interactor: qRScannerInteractor, router: qrScannerRouter)
        qRScannerInteractor.presenter = qRScannerPresenter
        qrScannerRouter.presenter = qRScannerPresenter
        qrScannerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrScannerRouter
    }

   @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}

class ChildQRScannerModule: QRScannerModule, ChildQRScannerModuleProtocol {
    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       forDelegate delegate: QRScannerModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard (self.router as? ChildQRScannerRouterProtocol) == nil else {
            (self.router as? ChildQRScannerRouterProtocol)?.presentViewWith(wireframe: wireframe,
                                                                            forDelegate: delegate,
                                                                            completion: completion)
            return
        }
        let qrScannerCameraManager = QRScannerCameraManager()
        let qRScannerInteractor = QRScannerInteractor(cameraManager: qrScannerCameraManager)
        let qrScannerRouter = ChildQRScannerRouter()
        let qRScannerPresenter = QRScannerPresenter(interactor: qRScannerInteractor, router: qrScannerRouter)
        qRScannerInteractor.presenter = qRScannerPresenter
        qrScannerRouter.presenter = qRScannerPresenter
        qrScannerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrScannerRouter
    }
}
