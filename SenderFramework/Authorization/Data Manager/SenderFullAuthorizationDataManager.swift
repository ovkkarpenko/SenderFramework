//
// Created by Roman Serga on 9/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc (MWSenderAuthorizationDataManager)
class SenderAuthorizationDataManager: NSObject, SenderAuthorizationDataManagerProtocol {
    @objc func saveUserInfo(_ userInfo: [AnyHashable: Any]) {
        CoreDataFacade.sharedInstance().setOwnerInfo(userInfo)
    }
}
