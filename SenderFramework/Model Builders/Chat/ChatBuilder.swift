//
// Created by Roman Serga on 23/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatBuilder)
public class ChatBuilder: NSObject, ChatBuilderProtocol {

    @objc public var chatSettingsBuildManager: ChatSettingsBuildManager
    @objc public var sendBarBuildManager: SendBarBuildManagerProtocol
    @objc public var itemBuildManager: ItemBuildManagerProtocol
    @objc public var membersBuildManager: ChatMemberBuildManagerProtocol

    @objc public init(chatSettingsBuildManager: ChatSettingsBuildManager,
                      sendBarBuildManager: SendBarBuildManagerProtocol,
                      itemBuildManager: ItemBuildManagerProtocol,
                      membersBuildManager: ChatMemberBuildManagerProtocol) {
        self.chatSettingsBuildManager = chatSettingsBuildManager
        self.sendBarBuildManager = sendBarBuildManager
        self.itemBuildManager = itemBuildManager
        self.membersBuildManager = membersBuildManager
    }

    //MARK : - Chat With Dictionary

    @objc public func validateDictionary(_ dictionary: [String: Any]) throws {
        if dictionary["chatId"] as? String == nil {
            let error = NSError(domain: "Cannot create chat without chatID", code: 666)
            throw error
        }
    }

    @objc public func setDataFrom(dictionary: [String: Any], to chat: Dialog) throws -> Dialog {

        do {
            try self.validateDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        chat.chatID = dictionary["chatId"] as! String
        chat.localID = dictionary["localId"] as? String
        chat.unreadCount = NSNumber(value: (dictionary["unread"] as? Int) ?? 0)
        chat.lastMessageText = dictionary["messageText"] as? String

        self.removeItemsOf(chat: chat)
        if let phone = dictionary["phone"] as? String { chat.addPhone(phone) }

        let messageTimeInterval = (dictionary["messageTime"] as? TimeInterval) ?? 0
        chat.lastMessageTime = Date(timeIntervalSince1970: messageTimeInterval / 1000)

        chat.name = dictionary["name"] as? String ?? ""
        chat.imageURL = dictionary["photo"] as? String

        chat.chatType = dictionary.transformedValueFor(key: "type",
                                                       transform: chatTypeFromString,
                                                       defaultValue: .undefined)

        chat.chatState = dictionary.transformedValueFor(key: "state",
                                                        transform: chatStateFromString,
                                                        defaultValue: .normal)

        if let sendBarDictionary = dictionary["bar"] as? [String: Any] {
            if let chatSendBar = chat.sendBar {
                chat.sendBar = self.sendBarBuildManager.setDataFrom(dictionary: sendBarDictionary, to: chatSendBar)
            } else {
                chat.sendBar = self.sendBarBuildManager.sendBarWith(dictionary: sendBarDictionary)
            }
        } else {
            if let chatBar = chat.sendBar { self.sendBarBuildManager.deleteSendBar(chatBar) }
            chat.sendBar = nil
        }

        if let sendBarDictionary = dictionary["barO"] as? [String: Any] {
            if let chatSendBar = chat.sendBar {
                chat.operatorSendBar = self.sendBarBuildManager.setDataFrom(dictionary: sendBarDictionary,
                                                                            to: chatSendBar)
            } else {
                chat.operatorSendBar = self.sendBarBuildManager.sendBarWith(dictionary: sendBarDictionary)
            }
        } else {
            if let operatorSendBar = chat.operatorSendBar { self.sendBarBuildManager.deleteSendBar(operatorSendBar) }
            chat.operatorSendBar = nil
        }

        let settingsDictionary = (dictionary["options"] as? [String: Any]) ?? [:]
        if let chatSetting = chat.chatSettings {
            chat.chatSettings = self.chatSettingsBuildManager.setDataFrom(dictionary: settingsDictionary,
                                                                         to: chatSetting)
        } else {
            chat.chatSettings = self.chatSettingsBuildManager.chatSettingsWith(dictionary: settingsDictionary)
        }

        let encryptionKey = dictionary["encryptionKey"] as? String
        let senderKey = dictionary["senderKey"] as? String

        chat.oldGroupKeysData = nil

        if chat.isP2P {
            chat.setP2PEncryptionKey(encryptionKey)
        } else if chat.isGroup {
            chat.setGroupEncryptionKey(encryptionKey, withSenderKey: senderKey, isOldKey: false)
        }

        self.removeMembersOf(chat: chat)
        var membersArray = [ChatMember]()

        /*
            We may get saved group chat info without members. For example while syncing.
            So we set chats as deleted only if we receive members dictionary
        */
        var receivedMembersDictionary = false
        if let membersDictionaries = dictionary["members"] as? [[String: Any]] {
            receivedMembersDictionary = true
            let p2pChat = chat.isP2P ? chat : nil
            membersArray = membersDictionaries.flatMap({
                return try? self.membersBuildManager.chatMemberWith(dictionary: $0, p2pChat: p2pChat)
            })
        }

        if chat.isP2P && membersArray.isEmpty {
            if let interlocutor = try? self.membersBuildManager.chatMemberWith(chat: chat),
               let owner = try? self.membersBuildManager.memberForOwner() {
                membersArray.append(interlocutor)
                membersArray.append(owner)
                interlocutor.contact.p2pChat = chat
            }
        }

        chat.addMembers(Set(membersArray))

        self.removeAdminsOf(chat: chat)
        let adminsUserIDs = dictionary["admins"] as? [String] ?? []
        let newAdmins = chat.members?.filter({ return adminsUserIDs.contains($0.contact.userID) }) ?? []
        chat.addAdmins(Set(newAdmins))

        if receivedMembersDictionary {
            if let members = chat.members {
                let membersUserIDs = Array(members).flatMap({return $0.contact.userID})
                if chat.isGroup,
                   let ownerContactUserID = (try? self.membersBuildManager.memberForOwner())?.contact.userID {
                    if !membersUserIDs.contains(ownerContactUserID) {
                        let activeUserID = (dictionary["actionUserId"] as? String) ?? ownerContactUserID
                        chat.chatState = activeUserID == ownerContactUserID ? .removed : .inactive
                    } else {
                        chat.chatState = .normal
                    }
                }
            } else {
                chat.chatState = .removed
            }
        }

        //TODO: Remove crutch after server fix https://itsm.privatbank.ua/predmine/senderios/issue/755411.htm
        if chat.isGroup && (chat.name?.isEmpty ?? true), let members = chat.members {
            chat.name = chatNameFrom(members: members)
        }

        return chat
    }

    @objc public func update(chat: Dialog, withDictionary dictionary: [String: Any]) throws -> Dialog {

        do {
            try self.validateDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        chat.chatID = dictionary["chatId"] as! String
        if let localID = dictionary["localId"] as? String {
            chat.localID = localID
        }
        if let unreadCount = dictionary["unread"] as? Int {
            chat.unreadCount = NSNumber(value: unreadCount)
        }
        if let lastMessageText = dictionary["messageText"] as? String {
            chat.lastMessageText = lastMessageText
            chat.updateLastMessage()
        }

        if let messageTimeInterval = dictionary["messageTime"] as? TimeInterval {
            chat.lastMessageTime = Date(timeIntervalSince1970: messageTimeInterval / 1000)
        }

        if let name = dictionary["name"] as? String {
            chat.name = name
        }
        if let imageURL = dictionary["photo"] as? String {
            chat.imageURL = imageURL
        }
        if let phone = dictionary["phone"] as? String {
            self.removeItemsOf(chat: chat)
            chat.addPhone(phone)
        }

        chat.chatType = dictionary.transformedValueFor(key: "type",
                                                       transform: chatTypeFromString,
                                                       defaultValue: chat.chatType)

        chat.chatState = dictionary.transformedValueFor(key: "state",
                                                        transform: chatStateFromString,
                                                        defaultValue: chat.chatState)

        let dictionaryToSendBar: (([String: Any]) -> BarModel?) = { (sendBarDictionary: [String: Any]) in
            return try? self.sendBarBuildManager.sendBarWith(dictionary: sendBarDictionary)
        }

        if let sendBarDictionary = dictionary["bar"] as? [String: Any] {
            if chat.sendBar != nil {
                self.sendBarBuildManager.update(sendBar: chat.sendBar!, with: sendBarDictionary)
            } else {
                chat.sendBar = dictionary.transformedValueFor(key: "bar",
                                                              transform: dictionaryToSendBar,
                                                              defaultValue: chat.sendBar)
            }
        }

        if let operatorSendBarDictionary = dictionary["barO"] as? [String: Any] {
            if chat.operatorSendBar != nil {
                self.sendBarBuildManager.update(sendBar: chat.operatorSendBar!, with: operatorSendBarDictionary)
            } else {
                chat.operatorSendBar = dictionary.transformedValueFor(key: "barO",
                                                              transform: dictionaryToSendBar,
                                                              defaultValue: chat.operatorSendBar)
            }
        }

        if let settingsDictionary = dictionary["options"] as? [String: Any] {
            if chat.chatSettings != nil {
                self.chatSettingsBuildManager.update(chatSettings: chat.chatSettings!,
                                                     with: settingsDictionary)
            } else {
                chat.chatSettings = self.chatSettingsBuildManager.chatSettingsWith(dictionary: settingsDictionary)
            }
        }

        if let encryptionKey = dictionary["encryptionKey"] as? String {
            if chat.isP2P {
                chat.setP2PEncryptionKey(encryptionKey)
            } else if chat.isGroup, let senderKey = dictionary["senderKey"] as? String {
                chat.setGroupEncryptionKey(encryptionKey, withSenderKey: senderKey, isOldKey: false)
            }
        }

        var membersArray = [ChatMember]()

        /*
            We update members by deleting all of them and then creating new.
            We also in update methods of ChatBuilder update property of chat only if we have a new value.
            So, we update group chats members only if we have received new value.
            For p2p if we didn't receive members (we currently don't receive them in chat info, but we may be),
            we delete and recreate members
        */
        var shouldUpdateMembers = false
        if let membersDictionaries = dictionary["members"] as? [[String: Any]] {
            shouldUpdateMembers = true
            let p2pChat = chat.isP2P ? chat : nil
            membersArray = membersDictionaries.flatMap({
                return try? self.membersBuildManager.chatMemberWith(dictionary: $0, p2pChat: p2pChat)
            })
        }

        if chat.isP2P && membersArray.isEmpty {
            shouldUpdateMembers = true
            if let interlocutor = try? self.membersBuildManager.chatMemberWith(chat: chat),
               let owner = try? self.membersBuildManager.memberForOwner() {
                membersArray.append(interlocutor)
                membersArray.append(owner)
                interlocutor.contact.p2pChat = chat
            }
        }

        if let adminsUserIDs = dictionary["admins"] as? [String] {
            self.removeAdminsOf(chat: chat)
            let newAdmins = chat.members?.filter({ return adminsUserIDs.contains($0.contact.userID) }) ?? []
            chat.addAdmins(Set(newAdmins))
        }

        if shouldUpdateMembers {
            self.removeMembersOf(chat: chat)
            chat.addMembers(Set(membersArray))

            /*
                Group chats doesn't use chatState currently.
                We won't receive state = removed after leaving chat or state = normal after joining.
                That's why after chat updating we analyze chat members and set chat as deleted,
                if there's no owner contact there.
                We do this only if we've received members dictionary in chat info,
                because it may be short chat info (like while syncing) and also
                because in update methods we update property only if we have a new value for it
            */

            if let members = chat.members {
                let membersUserIDs = Array(members).flatMap({return $0.contact.userID})
                if chat.isGroup,
                   let ownerContactUserID = (try? self.membersBuildManager.memberForOwner())?.contact.userID {
                   if !membersUserIDs.contains(ownerContactUserID) {
                       let activeUserID = (dictionary["actionUserId"] as? String) ?? ownerContactUserID
                       chat.chatState = activeUserID == ownerContactUserID ? .removed : .inactive
                   } else {
                       chat.chatState = .normal
                   }
                }
            } else {
                chat.chatState = .removed
            }
        }

        //TODO: Remove crutch after server fix https://itsm.privatbank.ua/predmine/senderios/issue/755411.htm
        if chat.isGroup && (chat.name?.isEmpty ?? true), let members = chat.members {
            chat.name = chatNameFrom(members: members)
        }

        return chat
    }

    //MARK: - Chat With Contact

    @objc public func validateUserContact(_ contact: Contact) throws {
        if contact.userID == nil {
            let error = NSError(domain: "Cannot create chat with contact without userID", code: 666)
            throw error
        }
    }

    @objc public func setDataFrom(contact: Contact, to chat: Dialog) throws -> Dialog {
        do {
            try self.validateUserContact(contact)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        let chatID = chatIDFromUserID(contact.userID)
        chat.chatID = chatID
        chat.name = contact.name ?? ""
        chat.imageURL = contact.imageURL
        self.removeItemsOf(chat: chat)
        chat.addItems(contact.items)
        chat.chatState = .undefined

        return chat
    }

    @objc public func update(chat: Dialog, withContact contact: Contact) throws -> Dialog {
        do {
            try self.validateUserContact(contact)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        if chat.name == nil, let name = contact.name { chat.name = name }
        if chat.imageURL == nil, let imageURL = contact.imageURL { chat.imageURL = imageURL }
        if let contactItems = contact.items {
            if let items = chat.items, items.isEmpty { self.removeItemsOf(chat: chat) }
            if chat.items == nil {
                chat.addItems(contactItems)
            }
        }

        return chat
    }

    //MARK : - Chat With Chat Settings

    @objc public func validateChatSettingsDictionary(_ chatSettings: [String: Any]) throws {
        if chatSettings["id"] as? String == nil {
            let error = NSError(domain: "Cannot create chat without chatID", code: 666)
            throw error
        }
    }

    @objc public func setDataFrom(chatSettingsDictionary: [String: Any], to chat: Dialog) throws -> Dialog {
        do {
            try self.validateChatSettingsDictionary(chatSettingsDictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        if let chatSettings = chat.chatSettings {
            chat.chatSettings = self.chatSettingsBuildManager.setDataFrom(dictionary: chatSettingsDictionary,
                                                                     to: chatSettings)
        } else {
            chat.chatSettings = self.chatSettingsBuildManager.chatSettingsWith(dictionary: chatSettingsDictionary)
        }

        return chat
    }

    @objc public func update(chat: Dialog,
                             withChatSettingsDictionary chatSettingsDictionary: [String: Any]) throws -> Dialog {

        do {
            try self.validateChatSettingsDictionary(chatSettingsDictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        if chat.chatSettings != nil {
            self.chatSettingsBuildManager.update(chatSettings: chat.chatSettings!,
                                                 with: chatSettingsDictionary)
        } else {
            chat.chatSettings = self.chatSettingsBuildManager.chatSettingsWith(dictionary: chatSettingsDictionary)
        }
        return chat
    }

    //MARK : - Setting ChatID

    @objc public func setChatID(_ chatID: String, to chat: Dialog) -> Dialog {
        chat.chatID = chatID
        return chat
    }

    private func removeMembersOf(chat: Dialog) {
        if let chatMembers = chat.members {
            chat.removeMembers(chatMembers)
            _ = chatMembers.map { self.membersBuildManager.deleteMember($0) }
        }
    }

    private func removeAdminsOf(chat: Dialog) {
        if let admins = chat.admins {
            chat.removeAdmins(admins)
            _ = admins.map { self.membersBuildManager.deleteMember($0) }
        }
    }

    private func removeItemsOf(chat: Dialog) {
        if let items = chat.items {
            chat.removeItems(items)
            for item in items { self.itemBuildManager.deleteItem(item) }
        }
    }

}

func chatNameFrom(members: Set<ChatMember>) -> String {
    return members.flatMap({return $0.contact.name}).joined(separator: " ")
}
