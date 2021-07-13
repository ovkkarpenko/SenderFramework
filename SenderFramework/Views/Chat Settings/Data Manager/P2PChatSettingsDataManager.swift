//
// Created by Roman Serga on 6/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class P2PChatSettingsDataManager: ChatSettingsDataManager, P2PChatSettingsDataManagerProtocol {
    func complainAbout(user: Contact, withText text: String, completion: ((Bool) -> Void)?) {
        guard let userID = user.userID else { completion?(false); return }
        ServerFacade.sharedInstance().sendComplaintAboutUser(withID: userID, withReason: text) { response, error in
            completion?(response != nil && error == nil)
        }
    }
}
