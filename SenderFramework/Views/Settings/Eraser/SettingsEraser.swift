//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SettingsEraser: SettingsEraserProtocol {

    func clearChatHistoryWith(completion: ((Bool, Error?) -> Void)?) {
        CoreDataFacade.sharedInstance().clearAllHistory()
        completion?(true, nil)
    }

    func disableDeviceWith(completion: ((Bool, Error?) -> Void)?) {
        CometController.sharedInstance().systemReset()
        completion?(true, nil)
    }

}
