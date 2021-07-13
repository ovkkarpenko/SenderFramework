//
// Created by Roman Serga on 21/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc (MWChatMemberBuilder)
public class ChatMemberBuilder: NSObject, ChatMemberBuilderProtocol {

    @objc public var contactBuildManager: ContactBuildManager

    @objc required public init(contactBuildManager: ContactBuildManager) {
        self.contactBuildManager = contactBuildManager

        super.init()
    }

    @objc public func validateMemberDictionary(_ dictionary: [String: Any]) throws {
        try self.contactBuildManager.contactBuilder.validateUserDictionary(dictionary)
    }

    @objc public func validateChat(_ chat: Dialog) throws {
        try self.contactBuildManager.contactBuilder.validateChat(chat)
    }

    @objc public func validateOwner(_ owner: Owner) throws {
        try self.contactBuildManager.contactBuilder.validateOwner(owner)
    }

    @objc public func setDataFrom(dictionary: [String: Any],
                                  toChatMember chatMember: ChatMember,
                                  p2pChat: Dialog?) throws -> ChatMember {
        let contact = try self.contactBuildManager.userWith(dictionary: dictionary, p2pChat: p2pChat)
        chatMember.contact = contact

        let stringToRole: (String) -> ChatMemberRole = { roleString in
            switch roleString {
            case "admin":
                return ChatMemberRole.admin
            default:
                return ChatMemberRole.user
            }
        }

        chatMember.role = dictionary.transformedValueFor(key: "role",
                                                         transform: stringToRole,
                                                         defaultValue: ChatMemberRole.user)

        return chatMember
    }

    
    @objc public func updateChatMember(_ chatMember: ChatMember,
                                       withDictionary dictionary: [String : Any]) throws -> ChatMember {
        try chatMember.contact = self.contactBuildManager.updateUser(chatMember.contact, withDictionary: dictionary)

        let stringToRole: (String) -> ChatMemberRole = { roleString in
            switch roleString {
            case "admin":
                return ChatMemberRole.admin
            default:
                return ChatMemberRole.user
            }
        }

        chatMember.role = dictionary.transformedValueFor(key: "role",
                                                         transform: stringToRole,
                                                         defaultValue: chatMember.role)

        return chatMember
    }

    @objc public func setDataFrom(chat: Dialog, toChatMember chatMember: ChatMember) throws -> ChatMember {
        chatMember.contact = try self.contactBuildManager.userWith(chat: chat)
        return chatMember
    }

    @objc public func updateChatMember(_ chatMember: ChatMember, withChat chat: Dialog) throws -> ChatMember {
        chatMember.contact = try self.contactBuildManager.updateContact(chatMember.contact, withChat: chat)
        return chatMember
    }

    @objc public func setDataFrom(owner: Owner, toChatMember chatMember: ChatMember) throws -> ChatMember {
        chatMember.contact = try self.contactBuildManager.userWith(owner: owner)
        return chatMember
    }

    @objc public func updateChatMember(_ chatMember: ChatMember, withOwner owner: Owner) throws -> ChatMember {
        chatMember.contact = try self.contactBuildManager.updateUser(chatMember.contact, withOwner: owner)
        return chatMember
    }

}
