//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderDeauthorizationModel)
public class SenderDeauthorizationModel: NSObject {
    @objc public var deviceUDID: String
    @objc public var developerID: String
    @objc public var deviceIMEI: String?
    @objc public var companyID: String?

    @objc public init(deviceUDID: String, developerID: String) {
        self.deviceUDID = deviceUDID
        self.developerID = developerID
        super.init()
    }
}
