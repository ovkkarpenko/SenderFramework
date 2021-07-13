//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWContactBuilder)
public class ContactBuilder: NSObject, ContactBuilderProtocol {

    @objc public var itemBuildManager: ItemBuildManagerProtocol
    @objc public weak var chatBuildManager: ChatBuildManagerProtocol!

    @objc convenience init(itemBuildManager: ItemBuildManagerProtocol,
                           chatBuildManager: ChatBuildManagerProtocol!) {
        self.init(itemBuildManager: itemBuildManager)
        self.chatBuildManager = chatBuildManager
    }

    @objc public init(itemBuildManager: ItemBuildManagerProtocol) {
        self.itemBuildManager = itemBuildManager
        super.init()
    }

    @objc public func validatePhoneBookContactDictionary(_ dictionary: [String: Any]) throws {
        if dictionary["localId"] as? String == nil {
            let error = NSError(domain: "Cannot create phone book contact without localID", code: 666)
            throw error
        }
    }

    @objc public func validateUserDictionary(_ dictionary: [String: Any]) throws {
        if dictionary["userId"] as? String == nil {
            let error = NSError(domain: "Cannot create user without userID", code: 666)
            throw error
        }
    }

    @objc public func validateChat(_ chat: Dialog) throws {
        if userIDFromChatID(chat.chatID) == nil {
            let error = NSError(domain: "Cannot create userID from chat", code: 666)
            throw error
        }
    }

    @objc public func validateOwner(_ owner: Owner) throws {
        if owner.ownerID == nil {
            let error = NSError(domain: "Cannot create user with owner without ID", code: 666)
            throw error
        }
    }

    @objc public func setDataFrom(dictionary: [String: Any],
                                  toUser user: Contact,
                                  p2pChat: Dialog?) throws -> Contact {
        do {
            try self.validateUserDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact", code: 666)
        }

        guard let chatBuildManager = self.chatBuildManager else {
            throw NSError(domain: "Cannot create contact. Contact builder doesn't have chatBuildManager", code: 666)
        }

        user.userID = dictionary["userId"] as? String
        user.localID = dictionary["localId"] as? String
        user.name = dictionary["name"] as? String
        user.imageURL = dictionary["photo"] as? String
        self.removeItemsOf(contact: user)

        if let phone = dictionary["phone"] as? String,
           let phoneItem = try? self.itemBuildManager.itemWith(phone: phone) {
            user.addItemsObject(phoneItem)
        }

        user.p2pChat = p2pChat

        if let userID = user.userID, user.p2pChat == nil {
            let chatID = chatIDFromUserID(userID)
            user.p2pChat = try? chatBuildManager.p2pChatWith(contact: user, isNewChat: nil)
        }

        return user
    }

    @objc public func update(user: Contact, withDictionary dictionary: [String: Any]) throws -> Contact {
        do {
            try self.validateUserDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact", code: 666)
        }

        guard let chatBuildManager = self.chatBuildManager else {
            throw NSError(domain: "Cannot update contact. Contact builder doesn't have chatBuildManager", code: 666)
        }

        if let userID = dictionary["userId"] as? String { user.userID = userID }
        if let localId = dictionary["localId"] as? String { user.localID = localId }
        if let name = dictionary["name"] as? String { user.name = name }
        if let imgUrl = dictionary["photo"] as? String { user.imageURL = imgUrl }

        if let phone = dictionary["phone"] as? String {
            self.removeItemsOf(contact: user)
            if let phoneItem = try? self.itemBuildManager.itemWith(phone: phone) {
                user.addItemsObject(phoneItem)
            }
        }

        if let userID = user.userID, user.p2pChat == nil {
            user.p2pChat = try? chatBuildManager.p2pChatWith(contact: user, isNewChat: nil)
        }

        return user
    }

    @objc public func setDataFrom(chat: Dialog, toUser user: Contact) throws -> Contact {
        do {
            try self.validateChat(chat)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot set data to contact with chat", code: 666)
        }

        user.userID = userIDFromChatID(chat.chatID)!
        user.name = chat.name
        user.imageURL = chat.imageURL
        self.removeItemsOf(contact: user)
        user.addItems(chat.items)
        user.isCompany = NSNumber(value: chat.chatType == .company)

        return user
    }

    @objc public func update(user: Contact, withChat chat: Dialog) throws -> Contact {
        do {
            try self.validateChat(chat)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot update contact with chat", code: 666)
        }

        return try setDataFrom(chat: chat, toUser: user)
    }

    @objc public func setDataFrom(owner: Owner, toUser user: Contact) throws -> Contact {
        do {
            try self.validateOwner(owner)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact with chat", code: 666)
        }

        user.userID = owner.ownerID
        user.name = owner.name
        user.imageURL = owner.ownimgurl
        self.removeItemsOf(contact: user)
        user.addPhone(owner.numberPhone)

        return user
    }

    @objc public func update(user: Contact, withOwner owner: Owner) throws -> Contact {
        do {
            try self.validateOwner(owner)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create contact with chat", code: 666)
        }

        return try self.setDataFrom(owner: owner, toUser: user)
    }

    @objc public func setDataFrom(dictionary: [String: Any], toPhoneBookContact contact: Contact) throws -> Contact {
        do {
            try self.validatePhoneBookContactDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create phone book contact", code: 666)
        }

        contact.localID = dictionary["localId"] as? String
        contact.name = dictionary["name"] as? String
        if let phone = dictionary["phone"] as? String,
           let phoneItem = try? self.itemBuildManager.itemWith(phone: phone) {
            contact.addItemsObject(phoneItem)
        }

        return contact
    }

    @objc public func update(phoneBookContact: Contact, withDictionary dictionary: [String: Any]) throws -> Contact {
        do {
            try self.validatePhoneBookContactDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create update phone book contact", code: 666)
        }

        if let localId = dictionary["localId"] as? String { phoneBookContact.localID = localId }
        if let name = dictionary["name"] as? String { phoneBookContact.name = name }
        if let phone = dictionary["phone"] as? String {
            self.removeItemsOf(contact: phoneBookContact)
            if let phoneItem = try? self.itemBuildManager.itemWith(phone: phone) {
                phoneBookContact.addItemsObject(phoneItem)
            }
        }

        return phoneBookContact
    }

    private func removeItemsOf(contact: Contact) {
        if let items = contact.items {
            contact.removeItems(items)
            for item in items { self.itemBuildManager.deleteItem(item) }
        }
    }

}
