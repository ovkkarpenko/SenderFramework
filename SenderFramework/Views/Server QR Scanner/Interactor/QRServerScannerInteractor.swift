//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRServerScannerInteractor: QRScannerInteractor {

    var dataManager: QRServerScannerDataManagerProtocol

    init(dataManager: QRServerScannerDataManagerProtocol, cameraManager: QRScannerCameraManagerProtocol) {
        self.dataManager = dataManager
        super.init(cameraManager: cameraManager)
    }

    override func stringWasScanned(_ string: String) {
        self.dataManager.sendQRString(string) { success, _ in
            if success { super.stringWasScanned(string) }
        }
    }

}
