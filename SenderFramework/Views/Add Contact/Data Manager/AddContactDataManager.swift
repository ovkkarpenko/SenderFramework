//
// Created by Roman Serga on 3/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddContactDataManager: AddContactDataManagerProtocol {

    func addContactWith(name: String, phone: String, completion: @escaping (([AnyHashable: Any]?, Error?) -> Void)) {
        ServerFacade.sharedInstance().addContact(withName: name, phone: phone, requestHandler: completion)
    }

}
