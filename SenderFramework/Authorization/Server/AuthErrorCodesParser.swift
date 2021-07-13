//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWAuthErrorCodesParser)
public class AuthErrorCodesParser: NSObject {

    class func parseErrorCode(_ errorCode: String) -> String {
        var errorMessage: String
        switch errorCode {
        case "error_send_ivr":
            errorMessage = SenderFrameworkLocalizedString("error_send_ivr")
        case "error_count_otp":
            errorMessage = SenderFrameworkLocalizedString("error_count_otp")
        case "error_timeout_otp":
            errorMessage = SenderFrameworkLocalizedString("error_timeout_otp")
        case "wrong_otp":
            errorMessage = SenderFrameworkLocalizedString("error_wrong_otp")
        case "blocked":
            errorMessage = SenderFrameworkLocalizedString("error_blocked")
        case "wrong_phone":
            errorMessage = SenderFrameworkLocalizedString("error_wrong_phone")
        case "timeout":
            errorMessage = SenderFrameworkLocalizedString("error_timeout")
        default:
            errorMessage = SenderFrameworkLocalizedString("error_unknown")
        }
        return errorMessage
    }

}
