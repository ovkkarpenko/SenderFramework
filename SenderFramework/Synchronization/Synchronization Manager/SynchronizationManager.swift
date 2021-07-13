//
// Created by Roman Serga on 27/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSynchronizationManagerInputProtocol)
public protocol SynchronizationManagerInputProtocol {

    func getSynchronizationDataWith(contacts: [[AnyHashable: Any]]?,
                                    isFullVersion: Bool,
                                    completion: @escaping ([AnyHashable: Any]?, Error?) -> Void)

    func getCompaniesCardsWith(completion: @escaping ([AnyHashable: Any]?, Error?) -> Void)

    func getPhoneBookWith(limit: Int, skip: Int, completion: @escaping ([AnyHashable: Any]?, Error?) -> Void)

    func getCompanyChats() -> [Dialog]

    func getUserInfoWith(completion: @escaping ([AnyHashable: Any]?, Error?) -> Void)
}

@objc (MWSynchronizationManagerProtocol)
public protocol SynchronizationManagerProtocol {

    typealias ChatsSynchronizationCompletion = ([Dialog]?, Error?) -> Void
    typealias CompanyCardsSynchronizationCompletion = ([CompanyCard]?, Error?) -> Void
    typealias PhoneBookSynchronizationCompletion = ([Contact]?, Error?) -> Void
    typealias UserInfoSynchronizationCompletion = ([AnyHashable: Any]?, Error?) -> Void

    var input: SynchronizationManagerInputProtocol { get set }
    var chatBuilderManager: ChatBuildManagerProtocol { get set }
    var contactBuildManager: ContactBuildManagerProtocol { get set }

    func startChatSynchronizationWith(contacts: [[AnyHashable: Any]]?,
                                      isFullVersion: Bool,
                                      completion: @escaping ChatsSynchronizationCompletion)
    func startCompaniesCardSynchronizationWith(completion: @escaping CompanyCardsSynchronizationCompletion)
    func syncPhoneBookWith(completion: @escaping PhoneBookSynchronizationCompletion)
    func syncUserInfoWith(completion: @escaping UserInfoSynchronizationCompletion)
}

@objc(MWSynchronizationManager)
public class SynchronizationManager: NSObject, SynchronizationManagerProtocol {

    @objc public var input: SynchronizationManagerInputProtocol
    @objc public var chatBuilderManager: ChatBuildManagerProtocol
    @objc public var contactBuildManager: ContactBuildManagerProtocol

    @objc public init(input: SynchronizationManagerInputProtocol,
                      chatBuilderManager: ChatBuildManagerProtocol,
                      contactBuildManager: ContactBuildManagerProtocol) {
        self.input = input
        self.chatBuilderManager = chatBuilderManager
        self.contactBuildManager = contactBuildManager
        super.init()
    }

    @objc public func startChatSynchronizationWith(contacts: [[AnyHashable: Any]]?,
                                                   isFullVersion: Bool,
                                                   completion: @escaping ChatsSynchronizationCompletion) {

        self.input.getSynchronizationDataWith(contacts: contacts,
                                              isFullVersion: isFullVersion) { response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let response = response else {
                let error = NSError(domain: "Cannot get sync data from dataStore", code: 666)
                completion(nil, error)
                return
            }

            var chats = [Dialog]()
            if let chatDictionaries = response["chats"] as? [[String: Any]] {
                chats = chatDictionaries.flatMap({ chatDictionary in
                    do {
                        return try self.chatBuilderManager.chatWith(dictionary: chatDictionary, isNewChat: nil)
                    } catch {
                        NSLog("Cannot create chat with dictionary: \(chatDictionary)")
                        return nil
                    }
                })
            }
            completion(chats, nil)
        }
    }

    @objc public func startCompaniesCardSynchronizationWith(completion: @escaping CompanyCardsSynchronizationCompletion) {
        self.input.getCompaniesCardsWith { response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let response = response else {
                let error = NSError(domain: "Cannot get companies card data from dataStore", code: 666)
                completion(nil, error)
                return
            }

            guard let defaultView = response["defaultView"] as? [String: Any],
                  let companiesWithCustomCard = response["noDefaultCompanies"] as? [String] else {
                completion(nil, nil)
                return
            }

            let allCompanies = self.input.getCompanyChats()
            let defaultCompanyCardDictionary = ["view": defaultView]

            var result = [CompanyCard]()
            for company in allCompanies {
                guard let userID = userIDFromChatID(company.chatID) else { continue }
                if !companiesWithCustomCard.contains(userID) {
                    //TODO: Refactor parsing
                    let companyCard = MWMessageCreator.shared.companyCardWith(dictionary: defaultCompanyCardDictionary,
                                                                              chat: company)
                    result.append(companyCard.0)
                    let isNewMessage = companyCard.1
                    if isNewMessage {
                        SenderCore.shared().interfaceUpdater.messagesWereAdded([companyCard.0])
                    } else {
                        SenderCore.shared().interfaceUpdater.messagesWereUpdated([companyCard.0])
                    }
                }
            }

            completion(result, error)
        }
    }

    @objc public func syncPhoneBookWith(completion: @escaping PhoneBookSynchronizationCompletion) {

        var contactDictionaries = [[String: Any]]()

        func getPhoneBook(skip: Int = 0, completion: @escaping ([[String: Any]]?, Error?) -> Void) {
            self.input.getPhoneBookWith(limit: 0, skip: skip) { response, error in
                guard error == nil else {
                    completion(nil, error)
                    return
                }

                guard let response = response else {
                    let error = NSError(domain: "Cannot get phone book from dataStore", code: 666)
                    completion(nil, error)
                    return
                }

                if let contacts = response["contacts"] as? [[String: Any]] {
                    contactDictionaries.append(contentsOf: contacts)
                }

                if let needMore = response["more"] as? Bool,
                   needMore,
                   let skip = response["skip"] as? Int {
                    getPhoneBook(skip: skip, completion: completion)
                } else {
                    completion(contactDictionaries, nil)
                }
            }
        }

        getPhoneBook { result, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            let contacts: [Contact]
            if let contactDictionaries = result {
                contacts = contactDictionaries.flatMap({
                    return try? self.contactBuildManager.phoneBookContactWith(dictionary: $0)
                })
            } else {
                contacts = []
            }
            completion(contacts, nil)
        }
    }

    @objc public func syncUserInfoWith(completion: @escaping UserInfoSynchronizationCompletion) {
        self.input.getUserInfoWith { response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let userInfo = response?["selfInfo"] as? [AnyHashable: Any] else {
                let error = NSError(domain: "Cannot get phone book from dataStore", code: 666)
                completion(nil, error)
                return
            }

            completion(userInfo, error)
        }
    }
}

public extension SynchronizationManager {
    @objc static func buildDefaultSynchronizationManager() -> SynchronizationManager {
        let input = SynchronizationManagerInput()
        let chatBuildManager = ChatBuildManager.buildDefaultChatBuildManager()
        let contactBuildManager = ContactBuildManager.buildDefaultContactBuildManager()
        return SynchronizationManager(input: input,
                                      chatBuilderManager: chatBuildManager,
                                      contactBuildManager: contactBuildManager)
    }
}
