//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class QRDisplayModule: NSObject, QRDisplayModuleProtocol {

    fileprivate weak var router: QRDisplayRouter?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  qrString: String,
                                  forDelegate delegate: QRDisplayModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let qrDisplayInteractor = QRDisplayInteractor()
        let qrDisplayRouter = QRDisplayRouter()
        let qrDisplayPresenter = QRDisplayPresenter(interactor: qrDisplayInteractor, router: qrDisplayRouter)
        qrDisplayInteractor.presenter = qrDisplayPresenter
        qrDisplayInteractor.updateWith(qrString: qrString)
        qrDisplayRouter.presenter = qrDisplayPresenter
        qrDisplayRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrDisplayRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }
}

class ChildQRDisplayModule: QRDisplayModule, ChildQRDisplayModuleProtocol {

    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       qrString: String,
                                                       forDelegate delegate: QRDisplayModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard (self.router as? ChildQRDisplayRouterProtocol) == nil else {
            (self.router as? ChildQRDisplayRouterProtocol)?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let qrDisplayInteractor = QRDisplayInteractor()
        let qrDisplayRouter = ChildQRDisplayRouter()
        let qrDisplayPresenter = QRDisplayPresenter(interactor: qrDisplayInteractor, router: qrDisplayRouter)
        qrDisplayInteractor.presenter = qrDisplayPresenter
        qrDisplayInteractor.updateWith(qrString: qrString)
        qrDisplayRouter.presenter = qrDisplayPresenter
        qrDisplayRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = qrDisplayRouter
    }
}
