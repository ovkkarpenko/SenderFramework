//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class QRServerScannerModule: QRScannerModule {

    fileprivate weak var router: QRScannerRouterProtocol?

    @objc override public func presentWith(wireframe: ViewControllerWireframe,
                                           forDelegate delegate: QRScannerModuleDelegate?,
                                           completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let qrScannerCameraManager = QRScannerCameraManager()
        let dataManager = QRServerScannerDataManager()
        let qRScannerInteractor = QRServerScannerInteractor(dataManager: dataManager,
                                                            cameraManager : qrScannerCameraManager)
        let qrScannerRouter = QRScannerRouter()
        let qRScannerPresenter = QRScannerPresenter(interactor: qRScannerInteractor, router: qrScannerRouter)
        qRScannerInteractor.presenter = qRScannerPresenter
        qrScannerRouter.presenter = qRScannerPresenter
        qrScannerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrScannerRouter
    }

    @objc override public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
        super.dismiss(completion: completion)
    }
}

class ChildQRServerScannerModule: QRServerScannerModule, ChildQRScannerModuleProtocol {

    public func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                              forDelegate delegate: QRScannerModuleDelegate?,
                                                              completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard (self.router as? ChildQRScannerRouter) == nil else {
            (self.router as? ChildQRScannerRouter)?.presentViewWith(wireframe: wireframe,
                                                                    forDelegate: delegate,
                                                                    completion: completion)
            return
        }
        let qrScannerCameraManager = QRScannerCameraManager()
        let dataManager = QRServerScannerDataManager()
        let qRScannerInteractor = QRServerScannerInteractor(dataManager: dataManager,
                                                            cameraManager : qrScannerCameraManager)
        let qrScannerRouter = ChildQRScannerRouter()
        let qRScannerPresenter = QRScannerPresenter(interactor: qRScannerInteractor, router: qrScannerRouter)
        qRScannerInteractor.presenter = qRScannerPresenter
        qrScannerRouter.presenter = qRScannerPresenter
        qrScannerRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrScannerRouter
    }

}
