//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol QRServerScannerDataManagerProtocol {
    func sendQRString(_ qrString: String, completion: ((Bool, Error?) -> Void)?)
}