//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public class QRScreenModule: NSObject, QRScreenModuleProtocol {

    var qrScannerModule: ChildQRScannerModuleProtocol
    var qrDisplayModule: ChildQRDisplayModuleProtocol

    fileprivate weak var qrScreenRouter: QRScreenRouter?

    public init(qrScannerModule: ChildQRScannerModuleProtocol, qrDisplayModule: ChildQRDisplayModuleProtocol) {
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
    }

    public func presentWith(wireframe: ViewControllerWireframe,
                            qrString: String,
                            forDelegate delegate: QRScreenModuleDelegate?,
                            completion: (() -> Void)?) {
        let containerRouter = QRScreenRouter(qrScannerModule: self.qrScannerModule,
                                             qrDisplayModule: self.qrDisplayModule)
        let containerInteractor = QRScreenInteractor()
        let containerPresenter = QRScreenPresenter(interactor: containerInteractor, router: containerRouter)
        containerInteractor.presenter = containerPresenter
        containerRouter.presenter = containerPresenter
        containerRouter.presentViewWith(wireframe: wireframe,
                                        qrString: qrString,
                                        forDelegate: delegate,
                                        completion: completion)
        self.qrScreenRouter = containerRouter
    }

    public func dismiss(completion: (() -> Void)?) {
        self.qrScreenRouter?.dismissView(completion: completion)
    }
}
