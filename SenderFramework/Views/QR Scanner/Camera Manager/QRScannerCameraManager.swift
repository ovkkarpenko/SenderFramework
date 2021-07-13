//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScannerCameraManager: QRScannerCameraManagerProtocol {

    func requestCameraAccess(completion: @escaping ((Bool) -> Void)) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { accessGranted in
            DispatchQueue.main.async {
                completion(accessGranted)
            }
        }
    }

}
