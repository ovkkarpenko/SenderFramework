//
// Created by Roman Serga on 6/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSenderSynchronizationProcessStorage)
public class SenderSynchronizationProcessStorage: NSObject, SenderSynchronizationProcessStorageProtocol {
    public func saveChats(_ chats: [Dialog]) {
        CoreDataFacade.sharedInstance().saveContext()
        CoreDataFacade.sharedInstance().getOwner().authorizationState = .syncedChats
        SenderCore.shared().interfaceUpdater.chatsWereChanged(chats)
    }

    public func saveNotUsers(_ notUsers: [Contact]) {
        CoreDataFacade.sharedInstance().saveContext()
        CoreDataFacade.sharedInstance().getOwner().authorizationState = .syncedNotUsers
    }

    public func saveCompanyCards(_ companyCards: [CompanyCard]) {
        CoreDataFacade.sharedInstance().saveContext()
        CoreDataFacade.sharedInstance().getOwner().authorizationState = .syncedAll
    }

    public func getLocalContacts() -> [[AnyHashable: Any]]? {
        let localContacts: [[AnyHashable: Any]]
        let addressBook = AddressBook()
        let grantedContactsAccess = addressBook.requestAccess()
        if grantedContactsAccess {
            addressBook.loadContactsNormalized(true)
            localContacts = addressBook.getContacts()
        } else {
            localContacts = []
        }
        return localContacts
    }

    public func saveUserInfo(_ userInfo: [AnyHashable: Any]) {
        CoreDataFacade.sharedInstance().setOwnerInfo(userInfo)
    }
}
