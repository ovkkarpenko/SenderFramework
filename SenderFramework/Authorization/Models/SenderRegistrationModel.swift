//
// Created by Roman Serga on 8/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderAuthorizationType)
public enum SenderAuthorizationType: NSInteger {
    case auth
    case sso
    case anonymous
}

@objc(MWSenderApplicationMode)
public enum SenderApplicationMode: NSInteger {
    case full
    case restricted
}

func stringFromSenderRegistrationApplicationMode(_ applicationMode: SenderAuthorizationType) -> String {
    switch applicationMode {
    case .auth:
        return "auth"
    case .sso:
        return "sso"
    case .anonymous:
        return "anonymous"
    }
}

@objc(MWSenderRegistrationModel)
public class SenderRegistrationModel: SenderAuthorizationStepModel {
    @objc public var deviceKey: String
    @objc public var authorizationType: SenderAuthorizationType
    @objc public var applicationMode: SenderApplicationMode

    @objc public init(deviceKey: String,
                      authorizationType: SenderAuthorizationType,
                      applicationMode: SenderApplicationMode,
                      step: SenderAuthorizationStep = .none) {
        self.deviceKey = deviceKey
        self.authorizationType = authorizationType
        self.applicationMode = applicationMode
        super.init(step: step)
    }
}
