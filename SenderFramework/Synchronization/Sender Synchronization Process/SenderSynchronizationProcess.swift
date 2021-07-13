//
// Created by Roman Serga on 6/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public extension SynchronizationProcessState {
    @objc static let syncingUserInfo = SynchronizationProcessState(name: "syncingUserInfo")
    @objc static let syncingChats = SynchronizationProcessState(name: "syncingChats")
    @objc static let syncingNotUsers = SynchronizationProcessState(name: "syncingNotUsers")
    @objc static let syncingCompanyCards = SynchronizationProcessState(name: "syncingCompanyCards")
}

//@objc(MWSenderSynchronizationProcessStorageProtocol)
@objc public protocol SenderSynchronizationProcessStorageProtocol {
    func saveChats(_ chats: [Dialog])
    func saveNotUsers(_ notUsers: [Contact])
    func saveCompanyCards(_ companyCards: [CompanyCard])
    func saveUserInfo(_ selfInfo: [AnyHashable: Any])

    func getLocalContacts() -> [[AnyHashable: Any]]?
}

@objc(MWSenderSynchronizationProcess)
public class SenderSynchronizationProcess: AbstractSynchronizationProcess {

    var synchronizationManager: SynchronizationManagerProtocol
    var storage: SenderSynchronizationProcessStorage

    @objc public init(synchronizationManager: SynchronizationManagerProtocol,
                      storage: SenderSynchronizationProcessStorage) {
        self.synchronizationManager = synchronizationManager
        self.storage = storage
        super.init()
    }

    @objc open override func nextStateAfter(state: SynchronizationProcessState) throws -> SynchronizationProcessState {
        switch state {
        case SynchronizationProcessState.none:
            return .syncingUserInfo
        case SynchronizationProcessState.syncingUserInfo:
            return .syncingChats
        case SynchronizationProcessState.syncingChats:
            return .syncingNotUsers
        case SynchronizationProcessState.syncingNotUsers:
            return .syncingCompanyCards
        case SynchronizationProcessState.syncingCompanyCards:
            return .finished
        default:
            throw NSError(domain: "Cannot handle state: \(state.name)", code: 1)
        }
    }

    @objc open override func performActionFor(state: SynchronizationProcessState,
                                              completion: @escaping ((Error?) -> Void)) {
        switch state {
        case SynchronizationProcessState.none:
            completion(nil)
        case SynchronizationProcessState.syncingUserInfo:
            self.syncUserInfoWith(completion: completion)
        case SynchronizationProcessState.syncingChats:
            self.syncChatsWith(completion: completion)
        case SynchronizationProcessState.syncingNotUsers:
            self.syncNotUsersWith(completion: completion)
        case SynchronizationProcessState.syncingCompanyCards:
            self.syncCompanyCardsWith(completion: completion)
        case SynchronizationProcessState.finished:
            completion(nil)
        default:
            completion(NSError(domain: "Cannot perform action for state: \(state.name)", code: 1))
        }
    }

    @objc public func syncChatsWith(completion: @escaping (Error?) -> Void) {
        let localContacts = self.storage.getLocalContacts() ?? []
        self.synchronizationManager.startChatSynchronizationWith(contacts: localContacts,
                                                                 isFullVersion: true) { chats, error in
            if let chats = chats { self.storage.saveChats(chats) }
            completion(error)
        }
    }

    @objc public func syncNotUsersWith(completion: @escaping (Error?) -> Void) {
        self.synchronizationManager.syncPhoneBookWith { contacts, error in
            if let contacts = contacts {
                self.storage.saveNotUsers(contacts)
            }
            completion(error)
        }
    }

    @objc public func syncCompanyCardsWith(completion: @escaping (Error?) -> Void) {
        self.synchronizationManager.startCompaniesCardSynchronizationWith { companyCards, error in
            if let companyCards = companyCards {
                self.storage.saveCompanyCards(companyCards)
            }
            completion(error)
        }
    }

    @objc public func syncUserInfoWith(completion: @escaping (Error?) -> Void) {
        self.synchronizationManager.syncUserInfoWith { userInfo, error in
            if let userInfo = userInfo {
                self.storage.saveUserInfo(userInfo)
            }
            completion(error)
        }
    }
}
