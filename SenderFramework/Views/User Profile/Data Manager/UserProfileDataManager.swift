//
// Created by Roman Serga on 22/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserProfileDataManager: UserProfileDataManagerProtocol {

    func loadUserPhone(completion: ((String?, Error?) -> Void)?) {
        let phone = CoreDataFacade.sharedInstance().getOwner().getPhoneNumber()
        completion?(phone, nil)
    }

    func loadUser() -> Owner {
        return CoreDataFacade.sharedInstance().getOwner()
    }

}
