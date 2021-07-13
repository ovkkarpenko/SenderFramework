//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWContactBuilder)
public protocol ContactCreatorProtocol {
    func createContact() -> Contact
    func userWith(userID: String) -> Contact?
    func contactWith(localID: String) -> Contact?

    func getOwnerContact() -> Contact?
    func getOwner() -> Owner
    func deleteContact(_ contact: Contact)
}

@objc(MWContactBuilderProtocol)
public protocol ContactBuilderProtocol {

    func validateUserDictionary(_ dictionary: [String: Any]) throws
    func validatePhoneBookContactDictionary(_ dictionary: [String: Any]) throws
    func validateChat(_ chat: Dialog) throws
    func validateOwner(_ owner: Owner) throws

    func setDataFrom(dictionary: [String: Any], toUser user: Contact, p2pChat: Dialog?) throws -> Contact
    func update(user: Contact, withDictionary dictionary: [String: Any]) throws -> Contact

    func setDataFrom(chat: Dialog, toUser user: Contact) throws -> Contact
    func update(user: Contact, withChat chat: Dialog) throws -> Contact

    func setDataFrom(owner: Owner, toUser user: Contact) throws -> Contact
    func update(user: Contact, withOwner owner: Owner) throws -> Contact

    func setDataFrom(dictionary: [String: Any], toPhoneBookContact contact: Contact) throws -> Contact
    func update(phoneBookContact: Contact, withDictionary dictionary: [String: Any]) throws -> Contact
}


@objc(MWContactBuildManagerProtocol)
public protocol ContactBuildManagerProtocol {

    var contactCreator: ContactCreatorProtocol { get }
    var contactBuilder: ContactBuilderProtocol { get }

    init(contactCreator: ContactCreatorProtocol,
         contactBuilder: ContactBuilderProtocol)

    func userWith(dictionary: [String: Any], p2pChat: Dialog?) throws -> Contact
    func updateUser(_ contact: Contact, withDictionary dictionary: [String: Any]) throws -> Contact

    func userWith(chat: Dialog) throws -> Contact
    func updateContact(_ contact: Contact, withChat chat: Dialog) throws -> Contact

    func userWith(owner: Owner) throws -> Contact
    func updateUser(_ contact: Contact, withOwner owner: Owner) throws -> Contact

    func phoneBookContactWith(dictionary: [String: Any]) throws -> Contact
    func updatePhoneBookContact(_ contact: Contact,
                                withDictionary dictionary: [String: Any]) throws -> Contact

    func deleteContact(_ contact: Contact)
}

@objc(MWContactBuildManager)
public class ContactBuildManager: NSObject, ContactBuildManagerProtocol {

    @objc public var contactCreator: ContactCreatorProtocol
    @objc public var contactBuilder: ContactBuilderProtocol

    @objc public required init(contactCreator: ContactCreatorProtocol,
                         contactBuilder: ContactBuilderProtocol) {
        self.contactCreator = contactCreator
        self.contactBuilder = contactBuilder
        super.init()
    }

    @objc public func userWith(dictionary: [String: Any], p2pChat: Dialog?) throws -> Contact {
        do {
            try self.contactBuilder.validateUserDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact", code: 666)
        }

        let userID = dictionary["userId"] as! String
        if let existingUser = self.contactCreator.userWith(userID: userID) {
            return try self.contactBuilder.update(user: existingUser, withDictionary: dictionary)
        } else {
            let user = self.contactCreator.createContact()
            return try self.contactBuilder.setDataFrom(dictionary: dictionary, toUser: user, p2pChat: p2pChat)
        }
    }

    @objc public func updateUser(_ contact: Contact, withDictionary dictionary: [String: Any]) throws -> Contact {
        do {
            try self.contactBuilder.validateUserDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact", code: 666)
        }

        return try self.contactBuilder.update(user: contact, withDictionary: dictionary)
    }

    @objc public func userWith(chat: Dialog) throws -> Contact {
        do {
            try self.contactBuilder.validateChat(chat)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact with chat", code: 666)
        }

        let userID = userIDFromChatID(chat.chatID)!
        if let existingUser = self.contactCreator.userWith(userID: userID) {
            return try self.contactBuilder.update(user: existingUser, withChat: chat)
        } else {
            let user = self.contactCreator.createContact()
            return try self.contactBuilder.setDataFrom(chat: chat, toUser: user)
        }
    }

    @objc public func updateContact(_ contact: Contact, withChat chat: Dialog) throws -> Contact {
        return try self.contactBuilder.update(user: contact, withChat: chat)
    }

    @objc public func userWith(owner: Owner) throws -> Contact {
        do {
            try self.contactBuilder.validateOwner(owner)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact with chat", code: 666)
        }

        let ownerID = owner.ownerID!
        if let existingOwnerContact = self.contactCreator.userWith(userID: ownerID) {
            return try self.contactBuilder.update(user: existingOwnerContact, withOwner: owner)
        } else {
            let ownerContact = self.contactCreator.createContact()
            return try self.contactBuilder.setDataFrom(owner: owner, toUser: ownerContact)
        }
    }

    @objc public func updateUser(_ contact: Contact, withOwner owner: Owner) throws -> Contact {
        return try self.contactBuilder.update(user: contact, withOwner: owner)
    }


    @objc public func phoneBookContactWith(dictionary: [String: Any]) throws -> Contact {
        do {
            try self.contactBuilder.validatePhoneBookContactDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create phone book contact", code: 666)
        }

        let localID = dictionary["localId"] as! String
        if let existingContact = self.contactCreator.contactWith(localID: localID) {
            return try self.updatePhoneBookContact(existingContact, withDictionary: dictionary)
        } else {
            let newContact = self.contactCreator.createContact()
            return try self.contactBuilder.setDataFrom(dictionary: dictionary, toPhoneBookContact: newContact)
        }
    }

    @objc public func updatePhoneBookContact(_ contact: Contact,
                                withDictionary dictionary: [String: Any]) throws -> Contact {
        return try self.contactBuilder.update(phoneBookContact: contact, withDictionary: dictionary)
    }

    @objc public func deleteContact(_ contact: Contact) {
        self.contactCreator.deleteContact(contact)
    }
}

public extension ContactBuildManager {
    static func buildDefaultContactBuildManager() -> ContactBuildManager {
        let barItemCreator = SendBarItemCreator()
        let barItemBuilder = SendBarItemBuilder()
        let barItemBuildManager = SendBarItemBuildManager(sendBarItemCreator: barItemCreator,
                                                          sendBarItemBuilder: barItemBuilder)

        let barCreator = SendBarCreator()
        let barBuilder = SendBarBuilder(sendBarItemBuildManager: barItemBuildManager)
        let barBuildManager = SendBarBuildManager(sendBarCreator: barCreator,
                                                  sendBarBuilder: barBuilder)

        let chatSettingsCreator = ChatSettingsCreator()
        let chatSettingsBuilder = ChatSettingsBuilder()
        let settingsBuildManager = ChatSettingsBuildManager(chatSettingsCreator: chatSettingsCreator,
                                                            chatSettingsBuilder: chatSettingsBuilder)

        let itemCreator = ItemCreator()
        let itemBuilder = ItemBuilder()
        let itemBuildManager = ItemBuildManager(itemCreator: itemCreator,
                                                itemBuilder: itemBuilder)

        let contactCreator = ContactCreator()
        let contactBuilder = ContactBuilder(itemBuildManager: itemBuildManager)
        let contactBuildManager = ContactBuildManager(contactCreator: contactCreator,
                                                      contactBuilder: contactBuilder)

        return contactBuildManager
    }
}
