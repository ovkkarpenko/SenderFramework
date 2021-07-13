//
// Created by Roman Serga on 19/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ChatInfoViewModelProtocol {
    var title: String { get }
    var subtitle: String { get }
    var chatBackgroundURL: URL? { get }
    var chatAvatarURL: URL? { get }
    var chatType: ChatType { get }
    var isP2P: Bool { get }
    var isEncrypted: Bool { get }
    var messagesStatus: MessageStatus { get }
    var messagesStatusDescription: String { get }
    var typingMessage: TypingMessageViewModel? { get }
    var unreadCount: Int { get }
    var sendBar: BarModel { get }
    var hasPhoneNumber: Bool { get }

    var chat: Dialog { get }

    func defaultChatAvatar(size: CGSize, rounded: Bool) -> UIImage?
}

struct ChatInfoViewModel: ChatInfoViewModelProtocol {

    var title: String { return self.chat.name ?? SenderFrameworkLocalizedString("new_chat_name_ph") }

    var subtitle: String {
        switch self.chatType {
        case .P2P:
            guard let p2pContact = self.chat.p2pContact else { return "" }
            return SenderFrameworkLocalizedString(p2pContact.isOnline.boolValue ? "online" : "offline")
        case .group:
            let membersCount = self.chat.members?.count ?? 0
            guard membersCount > 0 else { return "" }
            let format = SenderFrameworkLocalizedString(membersCount > 1 ? "chat_members_%i" : "chat_member_%i")
            return String(format: format, membersCount)
        case .company, .operator, .undefined:
            return ""
        }
    }

    var chatBackgroundURL: URL? { return self.chatAvatarURL }
    var chatAvatarURL: URL? { return self.chat.imageURL != nil ? URL(string: self.chat.imageURL!) : nil }
    var chatType: ChatType { return self.chat.chatType }
    var isP2P: Bool { return self.chat.isP2P }
    var isEncrypted: Bool { return self.chat.isEncrypted() }
    var messagesStatus: MessageStatus { return self.chat.lastMessageStatus }
    var messagesStatusDescription: String {
        switch self.chat.lastMessageStatus {
        case .unsent: return SenderFrameworkLocalizedString("📪")
        case .sent: return SenderFrameworkLocalizedString("📫")
        case .delivered: return SenderFrameworkLocalizedString("📬")
        case .read: return SenderFrameworkLocalizedString("📭")
        }
    }
    var typingMessage: TypingMessageViewModel?
    var unreadCount: Int { return self.chat.unreadCount.intValue }
    var sendBar: BarModel {
        let senderBar = CoreDataFacade.sharedInstance().senderBar()
        let chatSendBar = self.chat.sendBar ?? senderBar
        return self.chat.hasSendBar ? chatSendBar : senderBar
    }

    var hasPhoneNumber: Bool {
        return self.chat.isP2P && !self.chat.getPhoneFormatted(false).isEmpty
    }

    var chat: Dialog

    init(chat: Dialog) {
        self.chat = chat
    }

    mutating func updateWith(chat: Dialog) {
        self.chat = chat
    }

    func defaultChatAvatar(size: CGSize, rounded: Bool) -> UIImage? {
        let emoji = self.chat.defaultImageEmoji
        let backgroundImageName = self.chat.chatType == .P2P ? "icAccount" : nil
        return DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                              size: size,
                                                              rounded: rounded,
                                                              backgroundImageName: backgroundImageName)
    }

    //MARK : - Fabric methods

    func createTypingModelFor(users: [Contact]) -> TypingMessageViewModel {
        return TypingMessageViewModel(typingUsers: users)
    }

    //MARK : - Working with typing Contacts

    mutating func changeTypingUsers(newTypingUsers: [Contact]) -> TypingMessageViewModel? {
        self.typingMessage = newTypingUsers.isEmpty ? nil : self.createTypingModelFor(users: newTypingUsers)
        return self.typingMessage
    }
}
