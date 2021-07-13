//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatCreatorProtocol)
public protocol ChatCreatorProtocol {
    func createChat() -> Dialog
    func chatWith(id: String) -> Dialog?
    func deleteChat(_ chat: Dialog)
}

@objc(MWChatBuilderProtocol)
public protocol ChatBuilderProtocol {

    func setDataFrom(dictionary: [String: Any], to chat: Dialog) throws -> Dialog
    func update(chat: Dialog, withDictionary dictionary: [String: Any]) throws -> Dialog

    func setDataFrom(contact: Contact, to chat: Dialog) throws -> Dialog
    func update(chat: Dialog, withContact contact: Contact) throws -> Dialog

    func setDataFrom(chatSettingsDictionary: [String: Any], to chat: Dialog) throws -> Dialog
    func update(chat: Dialog, withChatSettingsDictionary chatSettingsDictionary: [String: Any]) throws -> Dialog

    func setChatID(_ chatID: String, to chat: Dialog) -> Dialog

    func validateDictionary(_ dictionary: [String: Any]) throws
    func validateUserContact(_ contact: Contact) throws
    func validateChatSettingsDictionary(_ chatSettings: [String: Any]) throws
}

@objc(MWChatBuildManagerProtocol)
public protocol ChatBuildManagerProtocol {

    var chatCreator: ChatCreatorProtocol { get }
    var chatBuilder: ChatBuilderProtocol { get }

    init(chatCreator: ChatCreatorProtocol, chatBuilder: ChatBuilderProtocol)

    func chatWith(dictionary: [String: Any], isNewChat: UnsafeMutablePointer<Bool>?) throws -> Dialog
    func p2pChatWith(contact: Contact, isNewChat: UnsafeMutablePointer<Bool>?) throws -> Dialog
    func chatWith(chatID: String, isNewChat: UnsafeMutablePointer<Bool>?) -> Dialog
    func chatWith(chatSettingsDictionary: [String: Any], isNewChat: UnsafeMutablePointer<Bool>?) throws -> Dialog

    func deleteChat(_ chat: Dialog)
}

@objc(MWChatBuildManager)
public class ChatBuildManager: NSObject, ChatBuildManagerProtocol {

    @objc public var chatCreator: ChatCreatorProtocol
    @objc public var chatBuilder: ChatBuilderProtocol

    @objc required public init(chatCreator: ChatCreatorProtocol, chatBuilder: ChatBuilderProtocol) {
        self.chatCreator = chatCreator
        self.chatBuilder = chatBuilder

        super.init()
    }

    @objc public func chatWith(dictionary: [String: Any],
                               isNewChat: UnsafeMutablePointer<Bool>? = nil) throws -> Dialog {
        do {
            try self.chatBuilder.validateDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        let chat: Dialog

        let chatID = dictionary["chatId"] as! String
        if let existingChat = self.chatCreator.chatWith(id: chatID) {
            isNewChat?.pointee = false
            chat = try self.chatBuilder.update(chat: existingChat, withDictionary: dictionary)
        } else {
            let newChat = self.chatCreator.createChat()
            isNewChat?.pointee = true
            chat = try self.chatBuilder.setDataFrom(dictionary: dictionary, to: newChat)
        }

        return chat
    }

    @objc public func p2pChatWith(contact: Contact, isNewChat: UnsafeMutablePointer<Bool>? = nil) throws -> Dialog {
        do {
            try self.chatBuilder.validateUserContact(contact)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        let chatID = chatIDFromUserID(contact.userID)

        let chat: Dialog

        if let existingChat = self.chatCreator.chatWith(id: chatID) {
            isNewChat?.pointee = false
            chat = try self.chatBuilder.update(chat: existingChat, withContact: contact)
        } else {
            let newChat = self.chatCreator.createChat()
            isNewChat?.pointee = true
            chat = try self.chatBuilder.setDataFrom(contact: contact, to: newChat)
        }

        return chat
    }

    @objc public func chatWith(chatID: String, isNewChat: UnsafeMutablePointer<Bool>? = nil) -> Dialog {
        if let existingChat = self.chatCreator.chatWith(id: chatID) {
            isNewChat?.pointee = false
            return existingChat
        } else {
            let newChat = self.chatCreator.createChat()
            isNewChat?.pointee = true
            self.chatBuilder.setChatID(chatID, to: newChat)
            return newChat
        }
    }

    @objc public func chatWith(chatSettingsDictionary: [String: Any],
                               isNewChat: UnsafeMutablePointer<Bool>?) throws -> Dialog {
        do {
            try self.chatBuilder.validateChatSettingsDictionary(chatSettingsDictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create chat", code: 666)
        }

        let chatID = chatSettingsDictionary["id"] as! String

        if let existingChat = self.chatCreator.chatWith(id: chatID) {
            isNewChat?.pointee = false
            try self.chatBuilder.setDataFrom(chatSettingsDictionary: chatSettingsDictionary, to: existingChat)
            return existingChat
        } else {
            let newChat = self.chatCreator.createChat()
            isNewChat?.pointee = true
            try self.chatBuilder.update(chat: newChat, withChatSettingsDictionary: chatSettingsDictionary)
            return newChat
        }
    }

    @objc public func deleteChat(_ chat: Dialog) {
        self.chatCreator.deleteChat(chat)
    }
}

public extension ChatBuildManager {
    @objc static func buildDefaultChatBuildManager() -> ChatBuildManager {
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

        let memberCreator = ChatMemberCreator()
        let memberBuilder = ChatMemberBuilder(contactBuildManager: contactBuildManager)
        let memberBuildManager = ChatMemberBuildManager(chatMemberCreator: memberCreator,
                                                        chatMemberBuilder: memberBuilder)

        let chatCreator = ChatCreator()
        let chatBuilder = ChatBuilder(chatSettingsBuildManager: settingsBuildManager,
                                      sendBarBuildManager: barBuildManager,
                                      itemBuildManager: itemBuildManager,
                                      membersBuildManager: memberBuildManager)

        let chatBuildManager = ChatBuildManager(chatCreator: chatCreator,
                                                chatBuilder: chatBuilder)

        contactBuilder.chatBuildManager = chatBuildManager

        return chatBuildManager
    }
}
