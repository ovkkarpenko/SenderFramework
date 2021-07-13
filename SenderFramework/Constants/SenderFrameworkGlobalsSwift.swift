//
//  SwiftConstants.swift
//  SENDER
//
//  Created by Roman Serga on 1/2/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

let IS_IPHONE = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone)
let IS_IPAD = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
let IS_RETINA = (UIScreen.main.scale >= 2.0)

let SCREEN_WIDTH = (UIScreen.main.bounds.size.width)
let SCREEN_HEIGHT = (UIScreen.main.bounds.size.height)
let SCREEN_MAX_LENGTH = (max(SCREEN_WIDTH, SCREEN_HEIGHT))
let SCREEN_MIN_LENGTH = (min(SCREEN_WIDTH, SCREEN_HEIGHT))

let IS_IPHONE_4_OR_LESS = (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
let IS_IPHONE_5 = (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
let IS_IPHONE_6 = (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
let IS_IPHONE_6P = (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

let SENDER_SHARED_CORE = SenderCore.shared()
let SENDER_FRAMEWORK_BUNDLE = Bundle.init(for: SenderCore.self)

let mainActionButtonHeight = CGFloat(56.0)

func synchronized<T>(_ lockObj: AnyObject!, closure: ()->T) -> T
{
    objc_sync_enter(lockObj)
    let retVal: T = closure()
    objc_sync_exit(lockObj)
    return retVal
}

public func SenderFrameworkLocalizedString(_ key: String,
                                           tableName: String? = "SenderFramework",
                                           value: String = "",
                                           comment: String = "") -> String {
    let bundle = SENDER_FRAMEWORK_BUNDLE
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: comment)
}
