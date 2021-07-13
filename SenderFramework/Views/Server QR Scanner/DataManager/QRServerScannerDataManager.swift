//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRServerScannerDataManager: QRServerScannerDataManagerProtocol {
    func sendQRString(_ qrString: String, completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendQR(qrString,
                                             chatID: nil,
                                             additionalParameters: nil) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }
}
