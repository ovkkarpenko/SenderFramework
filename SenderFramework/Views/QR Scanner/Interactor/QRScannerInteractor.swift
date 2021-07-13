//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScannerInteractor: QRScannerInteractorProtocol {
    weak var presenter: QRScannerPresenterProtocol?
    var cameraManager: QRScannerCameraManagerProtocol

    init(cameraManager: QRScannerCameraManagerProtocol) {
        self.cameraManager = cameraManager
    }

    func stringWasScanned(_ string: String) {
        self.presenter?.finishQRScannerWith(string: string)
    }

    func startWorking() {
        self.cameraManager.requestCameraAccess { accessGranted in
            if accessGranted {
                self.presenter?.startScanning()
            } else {
                self.presenter?.handleCameraNotAvailableError()
            }
        }
    }
}
