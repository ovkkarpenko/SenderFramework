//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScannerPresenter: QRScannerPresenterProtocol {

    weak var view: QRScannerViewProtocol?
    weak var delegate: QRScannerModuleDelegate?
    var router: QRScannerRouterProtocol?
    var interactor: QRScannerInteractorProtocol

    init(interactor: QRScannerInteractorProtocol, router: QRScannerRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.startWorking()
    }

    func stringWasScanned(_ string: String) {
        self.interactor.stringWasScanned(string)
    }

    func startScanning() {
        self.view?.startScanning()
    }

    func stopScanning() {
        self.view?.stopScanning()
    }

    func closeQRScanner() {
        self.delegate?.qrScannerModuleDidCancel()
    }

    func finishQRScannerWith(string: String) {
        self.view?.showSuccess {
            self.delegate?.qrScannerModuleDidFinishWith(string: string)
        }
    }

    func handleCameraNotAvailableError() {
        self.view?.showCameraNotAvailableError(completion: nil)
    }

}