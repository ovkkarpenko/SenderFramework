//
// Created by Roman Serga on 14/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSynchronizationManagerInput)
public class SynchronizationManagerInput: NSObject, SynchronizationManagerInputProtocol {

    public func getSynchronizationDataWith(contacts: [[AnyHashable: Any]]?,
                                           isFullVersion: Bool,
                                           completion: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        ServerFacade.sharedInstance().syncApplication(withContacts: contacts,
                                                      isFullVersion: isFullVersion) {response, error in
            completion(response, error)
        }
    }

    public func getCompaniesCardsWith(completion: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        ServerFacade.sharedInstance().getCompanyCards({response, error in
            completion(response, error)
        })
    }

    public func getPhoneBookWith(limit: Int, skip: Int, completion: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        ServerFacade.sharedInstance().syncPhoneBook(withLimit: limit, skip: skip, completionHandler: completion)
    }

    public func getCompanyChats() -> [Dialog] {
        return CoreDataFacade.sharedInstance().getCompanyChats()
    }

    public func getUserInfoWith(completion: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        ServerFacade.sharedInstance().getSelfInfo(completion: completion)
    }
}
