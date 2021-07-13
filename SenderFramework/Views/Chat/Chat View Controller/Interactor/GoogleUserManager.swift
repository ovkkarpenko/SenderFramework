//
// Created by Roman Serga on 10/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension MWGoogleUser {
    func dictionaryRepresentation() -> [String: Any] {
        return ["accessToken": self.accessToken ?? "",
                "userId": self.userID ?? "",
                "idToken": self.idToken ?? "",
                "fullName": self.fullName ?? "",
                "givenName": self.givenName ?? "",
                "familyName": self.familyName ?? "",
                "email": self.email ?? ""]
    }
}

class GoogleUserManager: GoogleUserManagerProtocol {
    func saveGoogleUser(_ googleUser: MWGoogleUser, completion: ((Bool, Error?) -> Void)?) {
        let googleUserDictionary = googleUser.dictionaryRepresentation()
        CoreDataFacade.sharedInstance().owner.setGoogleAccount(googleUserDictionary)
        ServerFacade.sharedInstance().sendGoogleToken(toServer: googleUser.accessToken ?? "") { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }
}
