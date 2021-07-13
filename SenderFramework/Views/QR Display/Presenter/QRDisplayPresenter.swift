//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRDisplayPresenter: QRDisplayPresenterProtocol {
    weak var view: QRDisplayViewProtocol?
    weak var delegate: QRDisplayModuleDelegate?

    var router: QRDisplayRouterProtocol?
    var interactor: QRDisplayInteractorProtocol

    init(interactor: QRDisplayInteractorProtocol, router: QRDisplayRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func qrStringWasUpdated(_ qrString: String) {
        self.view?.updateWith(qrString: qrString)
    }

    func closeQRDisplay() {
        self.delegate?.qrDisplayModuleDidCancel()
    }

}
