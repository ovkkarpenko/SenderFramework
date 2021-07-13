//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScreenPresenter: QRScreenPresenterProtocol {

    weak var view: QRScreenViewProtocol?
    weak var delegate: QRScreenModuleDelegate?
    var router: QRScreenRouterProtocol?
    var interactor: QRScreenInteractorProtocol

    init(interactor: QRScreenInteractorProtocol, router: QRScreenRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func qrScannerModuleDidCancel() {
        self.closeQRScreen()
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.closeQRScreen()
    }

    func qrDisplayModuleDidCancel() {
        self.closeQRScreen()
    }

    func closeQRScreen() {
        self.delegate?.qrScreenModuleDidCancel()
    }

    func viewWasLoaded() {
        self.interactor.setInitialState()
    }

    func stateWasUpdated(_ newState: QRScreenState) {
        switch newState {
            case .scanning:
                self.router?.showQRScanner()
            case .displayingQR:
                self.router?.showQRImage()
        }
        self.view?.updateWith(state: newState)
    }

    func changeViewState() {
        self.interactor.changeState()
    }
}
