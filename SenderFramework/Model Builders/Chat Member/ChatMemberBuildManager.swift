//
// Created by Roman Serga on 21/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatMemberCreatorProtocol)
public protocol ChatMemberCreatorProtocol {
    func createChatMember() -> ChatMember
    func getOwner() -> Owner

    func deleteMember(_ member: ChatMember)
}

@objc(MWChatMemberBuilderProtocol)
public protocol ChatMemberBuilderProtocol {

    func validateMemberDictionary(_ dictionary: [String: Any]) throws
    func validateChat(_ chat: Dialog) throws
    func validateOwner(_ owner: Owner) throws

    func setDataFrom(dictionary: [String: Any],
                     toChatMember chatMember: ChatMember,
                     p2pChat: Dialog?) throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withDictionary dictionary: [String: Any]) throws -> ChatMember

    func setDataFrom(chat: Dialog, toChatMember chatMember: ChatMember) throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withChat chat: Dialog) throws -> ChatMember

    func setDataFrom(owner: Owner, toChatMember chatMember: ChatMember) throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withOwner owner: Owner) throws -> ChatMember
}

@objc(MWChatMemberBuildManagerProtocol)
public protocol ChatMemberBuildManagerProtocol {

    var chatMemberCreator: ChatMemberCreatorProtocol { get }
    var chatMemberBuilder: ChatMemberBuilderProtocol { get }

    init(chatMemberCreator: ChatMemberCreatorProtocol,
         chatMemberBuilder: ChatMemberBuilderProtocol)

    func chatMemberWith(dictionary: [String: Any], p2pChat: Dialog?) throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withDictionary dictionary: [String: Any]) throws -> ChatMember

    func chatMemberWith(chat: Dialog) throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withChat chat: Dialog) throws -> ChatMember

    func memberForOwner() throws -> ChatMember
    func updateChatMember(_ chatMember: ChatMember, withOwner owner: Owner) throws -> ChatMember

    func deleteMember(_ member: ChatMember)
}

@objc(MWChatMemberBuildManager)
public class ChatMemberBuildManager: NSObject, ChatMemberBuildManagerProtocol {

    @objc public var chatMemberCreator: ChatMemberCreatorProtocol
    @objc public var chatMemberBuilder: ChatMemberBuilderProtocol

    @objc required public init(chatMemberCreator: ChatMemberCreatorProtocol,
                               chatMemberBuilder: ChatMemberBuilderProtocol) {
        self.chatMemberCreator = chatMemberCreator
        self.chatMemberBuilder = chatMemberBuilder

        super.init()
    }

    @objc public func chatMemberWith(dictionary: [String: Any], p2pChat: Dialog?) throws -> ChatMember {
        do {
            try self.chatMemberBuilder.validateMemberDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create member", code: 666)
        }

        let chatMember = chatMemberCreator.createChatMember()
        try self.chatMemberBuilder.setDataFrom(dictionary: dictionary, toChatMember: chatMember, p2pChat: p2pChat)
        return chatMember
    }

    @objc public func updateChatMember(_ chatMember: ChatMember,
                                 withDictionary dictionary: [String: Any]) throws -> ChatMember {
        do {
            try self.chatMemberBuilder.validateMemberDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot update member", code: 666)
        }

        return try self.chatMemberBuilder.updateChatMember(chatMember, withDictionary: dictionary)
    }

    @objc public func chatMemberWith(chat: Dialog) throws -> ChatMember {
        do {
            try self.chatMemberBuilder.validateChat(chat)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create member", code: 666)
        }

        let chatMember = chatMemberCreator.createChatMember()
        try self.chatMemberBuilder.setDataFrom(chat: chat, toChatMember: chatMember)
        return chatMember
    }

    @objc public func updateChatMember(_ chatMember: ChatMember, withChat chat: Dialog) throws -> ChatMember {
        do {
            try self.chatMemberBuilder.validateChat(chat)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot update member", code: 666)
        }

        return try self.chatMemberBuilder.updateChatMember(chatMember, withChat: chat)
    }

    @objc public func memberForOwner() throws -> ChatMember {
        let ownerMember = self.chatMemberCreator.createChatMember()
        let owner = self.chatMemberCreator.getOwner()
        do {
            try self.chatMemberBuilder.validateOwner(owner)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create owner member", code: 666)
        }

        return try self.chatMemberBuilder.setDataFrom(owner: owner, toChatMember: ownerMember)
    }

    @objc public func updateChatMember(_ chatMember: ChatMember, withOwner owner: Owner) throws -> ChatMember {
        do {
            try self.chatMemberBuilder.validateOwner(owner)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot update member with owner", code: 666)
        }

        return try self.chatMemberBuilder.updateChatMember(chatMember, withOwner: owner)
    }

    @objc public func deleteMember(_ member: ChatMember) {
        self.chatMemberCreator.deleteMember(member)
    }

}
