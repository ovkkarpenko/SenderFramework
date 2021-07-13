//
// Created by Roman Serga on 6/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import libPhoneNumber_iOS

public struct SelectableChatSetting<ValueType, DescriptionType> {
    let options: [(ValueType, DescriptionType)]
    var selectedIndex: Int
    var selectedOption: (ValueType, DescriptionType) { return self.options[self.selectedIndex] }
    var identifier: String
    var description: String?
}

public struct ChatSettingsViewModel {
    static let muteChatNotificationIdentifier = "muteChatNotificationIdentifier"
    static let hidePushNotificationIdentifier = "hidePushNotificationIdentifier"
    static let hideTextNotificationIdentifier = "hideTextNotificationIdentifier"
    static let hideCounterNotificationIdentifier = "hideCounterNotificationIdentifier"

    var isBlocked: Bool { return self.chatSettings.blockChat?.boolValue ?? false }
    var isFavorite: Bool { return self.chatSettings.favChat?.boolValue ?? false }
    private(set) var notificationsOptions: [SelectableChatSetting<ChatSettingsNotificationType, String>]

    var chatSettings: DialogSetting

    mutating func updateWith(chatSettings: DialogSetting) {
        self.chatSettings = chatSettings
    }
}

public struct ChatSettingsMemberViewModel {
    var name: String { return self.member.contact.name }

    var avatarURL: URL? {
        return self.member.contact.p2pChat.parsedImageURL ?? self.member.contact.parsedImageURL
    }

    var member: ChatMember
    var isOwner: Bool

    func defaultAvatarWith(size: CGSize, rounded: Bool) -> UIImage? {
        let emoji = self.member.contact.p2pChat?.defaultImageEmoji ?? self.member.contact.defaultImageEmoji
        return DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                              size: size,
                                                              rounded: rounded,
                                                              backgroundImageName: "icAccount")
    }

    init(member: ChatMember) {
        self.member = member
        let ownerUserID = CoreDataFacade.sharedInstance().ownerUDID()
        self.isOwner = member.contact.userID == ownerUserID
    }

    mutating func updateWith(member: ChatMember) {
        self.member = member
        let ownerUserID = CoreDataFacade.sharedInstance().ownerUDID()
        self.isOwner = member.contact.userID == ownerUserID
    }
}

public struct ChatSettingsPhoneViewModel {
    var description: String {
        return self.item.type ?? ""
    }

    var phone: String {
        let phoneNumberUtil = NBPhoneNumberUtil()
        let phone = self.item.value!.hasPrefix("+") ? self.item.value! : "+" + self.item.value!
        if let parsedNumber = try? phoneNumberUtil.parse(phone, defaultRegion: "UA"),
           let formattedPhone = try? phoneNumberUtil.format(parsedNumber, numberFormat: .INTERNATIONAL) {
            return formattedPhone
        } else {
            return phone
        }
    }

    var item: Item

    init?(item: Item) {
        guard item.value != nil else { return nil }
        self.item = item
    }

    mutating func updateWith(item: Item) throws {
        guard item.value != nil else {
            let error = NSError(domain: "Item has no value", code: 666)
            throw error
        }
        self.item = item
    }
}

public struct ChatSettingsChatViewModel {
    var title: String { return self.chat.name ?? SenderFrameworkLocalizedString("new_chat_name_ph") }

    var subtitle: String {
        switch self.chatType {
        case .P2P:
            return self.chat.chatDescription ?? ""
        case .group:
            let membersCount = self.chat.members?.count ?? 0
            guard membersCount > 0 else { return "" }
            let format = SenderFrameworkLocalizedString(membersCount > 1 ? "chat_members_%i" : "chat_member_%i")
            return String(format: format, membersCount)
        case .company, .operator, .undefined:
            return ""
        }
    }

    var chatAvatarURL: URL? { return self.chat.imageURL != nil ? URL(string: self.chat.imageURL!) : nil }
    var chatType: ChatType { return self.chat.chatType }
    var isP2P: Bool { return self.chat.isP2P }
    var isEncrypted: Bool { return self.chat.isEncrypted() }
    var isEditable: Bool { return self.chatType != .company }
    var isEncryptionAvailable: Bool { return self.chatType != .company }
    var isEncryptionSettable: Bool { return self.chatType == .group }
    var isFavorite: Bool { return self.chatSettings.isFavorite }
    var isBlocked: Bool { return self.chatSettings.isBlocked }
    var isDeleted: Bool { return self.chat.chatState == .removed || self.chat.chatState == .inactive }
    var isDeletable: Bool { return self.chat.chatID != "user+sender" }

    func defaultChatAvatarWith(size: CGSize, rounded: Bool) -> UIImage? {
        let emoji = self.chat.defaultImageEmoji
        let backgroundImageName = self.chat.chatType == .P2P ? "icAccount" : nil
        return DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                              size: size,
                                                              rounded: rounded,
                                                              backgroundImageName: backgroundImageName)
    }

    var hasPhoneNumber: Bool {
        return self.chat.isP2P && !self.chat.getPhoneFormatted(false).isEmpty
    }

    private(set) var phoneNumbers: [ChatSettingsPhoneViewModel]?

    private(set) var members: [ChatSettingsMemberViewModel]

    var chatSettings: ChatSettingsViewModel

    var chat: Dialog

    init(chat: Dialog,
         chatSettings: ChatSettingsViewModel) {
        self.chat = chat
        self.members = []
        self.chatSettings = chatSettings
        self.setMembersFromChat(chat: self.chat)
        self.setPhoneNumbersFromChat(chat: self.chat)
    }

    mutating func updateWith(chat: Dialog) {
        self.chat = chat
        self.setMembersFromChat(chat: self.chat)
        self.setPhoneNumbersFromChat(chat: self.chat)
    }

    private mutating func setMembersFromChat(chat: Dialog) {
        guard let chatMembers = chat.members else { self.members = []; return }
        var ownerMember: ChatSettingsMemberViewModel? = nil
        let memberViewModels = chatMembers.flatMap({ (member: ChatMember) -> ChatSettingsMemberViewModel? in
            let member = ChatSettingsMemberViewModel(member: member)
            guard !member.isOwner else { ownerMember = member; return nil }
            return member
        }).sorted(by: { $0.name < $1.name })
        self.members = [ownerMember].flatMap({$0}) + memberViewModels
    }

    private mutating func setPhoneNumbersFromChat(chat: Dialog) {
        guard let chatItems = self.chat.items else { self.phoneNumbers = nil; return }
        self.phoneNumbers = chatItems.flatMap { ChatSettingsPhoneViewModel(item: $0) }
    }
}
