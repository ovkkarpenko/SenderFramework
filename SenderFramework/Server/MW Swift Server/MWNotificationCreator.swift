//
//  MWNotificationCreator.swift
//  SENDER
//
//  Created by Eugene Gilko on 6/3/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

open class MWNotificationCreator: NSObject {

    static let shared = MWNotificationCreator()

    open func setNotificationMessageFromInfo(_ dictionary: [String:AnyObject], chat: Dialog) -> (Message, Bool)? {

        guard let packetID = dictionary["packetId"] as? Int,
              let model = dictionary["model"] as? [String: Any?],
              let actionType = model["type"] as? String,
              let users = model["users"] as? [[String: Any]] else { return nil }

        let actionUserDictionary = model["actionUser"] as? [String: Any] ?? [:]
        let actionUserID = actionUserDictionary["userId"] as? String
        let ownerID = CoreDataFacade.sharedInstance().getOwner().ownerID
        let actionUserName = (actionUserDictionary["name"] as? String) ?? "unknown_user".localized
        var usersList = [String: String]()
        users.forEach { userDictionary in
            guard let userID = userDictionary["userId"] as? String else { return }
            let userName = (userDictionary["name"] as? String) ?? ""
            return usersList[userID] = userName
        }
        guard let notificationText = self.generateNotificationTextWith(users: usersList,
                                                                       actionUserID: actionUserID,
                                                                       actionUserName: actionUserName,
                                                                       actionType: actionType,
                                                                       ownerUserID: ownerID ?? "") else { return nil }

        let notification = self.createNotificationWith(data: dictionary,
                                                       text: notificationText,
                                                       users: usersList,
                                                       actionUserID: actionUserID ?? "",
                                                       actionUserName: actionUserName,
                                                       actionType: actionType,
                                                       notificationType: "NOTIFICATION",
                                                       packetID: packetID.description,
                                                       chat:chat)
        return notification
    }

    func generateNotificationTextWith(users: [String: String],
                                      actionUserID: String?,
                                      actionUserName: String,
                                      actionType: String,
                                      ownerUserID: String) -> String? {
        let isOwnerAction = (actionUserID != nil && actionUserID! == ownerUserID)
        let meInUsers = users.contains { $0.0 == ownerUserID }

        let notificationText: String?

        switch actionType {
        case "add":
            notificationText = self.addNotificationTextWith(actionUserName: actionUserName,
                                                            users: users,
                                                            ownerUserID: ownerUserID,
                                                            isOwnerInUsers: meInUsers,
                                                            isOwnerAction: isOwnerAction)
        case "del":
            notificationText = deleteNotificationTextWith(actionUserName: actionUserName,
                                                          users: users,
                                                          ownerUserID: ownerUserID,
                                                          isOwnerInUsers: meInUsers,
                                                          isOwnerAction: isOwnerAction)
        case "leave":
            notificationText = leaveNotificationTextWith(users: users,
                                                         ownerUserID: ownerUserID,
                                                         isOwnerAction: isOwnerAction)
        default:
            notificationText = nil
        }

        return notificationText
    }

    func descriptionOf(users: [String: String], excludeOwnerIfNecessary: Bool, ownerUserID: String) -> String {
        var filteredUsers = users
        if excludeOwnerIfNecessary { filteredUsers[ownerUserID] = nil }
        let usersCount = filteredUsers.count
        let usersString: String
        if usersCount > 1 {
            usersString = String(format: SenderFrameworkLocalizedString("notify_%i_users"), usersCount)
        } else {
            usersString = filteredUsers.values.first ?? SenderFrameworkLocalizedString("unknown_user")
        }
        return usersString
    }

    func addNotificationTextWith(actionUserName: String,
                                 users: [String: String],
                                 ownerUserID: String,
                                 isOwnerInUsers: Bool,
                                 isOwnerAction: Bool) -> String {
        let usersDescription = descriptionOf(users: users, excludeOwnerIfNecessary: true, ownerUserID: ownerUserID)
        let notificationText: String
        if isOwnerInUsers {
            if users.count == 1 {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_user_%@_add_to_chat_you"),
                                          actionUserName)
            } else {
                let format = SenderFrameworkLocalizedString("notify_user_%@_add_to_chat_you_and_%@")
                notificationText = String(format: format, actionUserName, usersDescription)
            }
        } else {
            if isOwnerAction {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_you_add_%@_to_chat"),
                                          usersDescription)
            } else {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_user_%@_add_%@_to_chat"),
                                          actionUserName, usersDescription)
            }
        }
        return notificationText
    }

    func deleteNotificationTextWith(actionUserName: String,
                                    users: [String: String],
                                    ownerUserID: String,
                                    isOwnerInUsers: Bool,
                                    isOwnerAction: Bool) -> String {
        let usersDescription = descriptionOf(users: users, excludeOwnerIfNecessary: true, ownerUserID: ownerUserID)
        let notificationText: String
        if isOwnerInUsers {
            if users.count == 1 {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_user_%@_del_from_chat_you"),
                                          actionUserName)
            } else {
                let format = SenderFrameworkLocalizedString("notify_user_%@_del_from_chat_you_and_%@")
                notificationText = String(format: format, actionUserName, usersDescription)
            }
        } else {
            if isOwnerAction {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_you_del_%@_from_chat"),
                                          usersDescription)
            } else {
                notificationText = String(format: SenderFrameworkLocalizedString("notify_user_%@_del_%@_from_chat"),
                                          actionUserName, usersDescription)
            }
        }
        return notificationText
    }

    func leaveNotificationTextWith(users: [String: String],
                                   ownerUserID: String,
                                   isOwnerAction: Bool) -> String {
        let usersDescription = descriptionOf(users: users, excludeOwnerIfNecessary: true, ownerUserID: ownerUserID)
        let notificationText: String
        if isOwnerAction {
            notificationText = String(format:  SenderFrameworkLocalizedString("notify_you_leave_chat"))
        } else {
            notificationText = String(format:  SenderFrameworkLocalizedString("notify_user_%@_leave_chat"),
                                      usersDescription)
        }
        return notificationText
    }

    fileprivate func createNotificationWith(data: [String: Any],
                                            text: String,
                                            users: [String: String]?,
                                            actionUserID: String,
                                            actionUserName: String,
                                            actionType: String,
                                            notificationType: String,
                                            packetID: String,
                                            chat: Dialog) -> (Message, Bool)? {

        guard let chatID = chat.chatID else { return nil }

        let mesID = MWMessageCreator.shared.createMoID(packetID, chatID: chatID)
        let isNewNotification: Bool
        let notification: Message
        if let existingNotification = CoreDataFacade.sharedInstance().message(byId: mesID) {
            notification = existingNotification
            isNewNotification = false
        } else {
            notification = MWMessageCreator.shared.getNewRegMessage(mesID)
            isNewNotification = true
        }

        let usersList = users ?? [String: String]()
        let model = ["text": text,
                     "users": usersList,
                     "actionUserID": actionUserID,
                     "actionUserName": actionUserName,
                     "action": actionType] as [String: Any]

        do {
            notification.data = try JSONSerialization.data(withJSONObject: model, options: .prettyPrinted)
        } catch {
        }

        notification.title = text
        notification.type = notificationType

        if let from = data["from"] as? String {
            notification.fromId = from
        }

        var creationTime: Date? = nil
        if let timeInterval = data["created"] as? Double {
            creationTime = Date.init(timeIntervalSince1970: (timeInterval / 1000))
        }

        CoreDataFacade.sharedInstance().setNewPacketID(packetID,
                                                       moID: nil,
                                                       andCreationTime: creationTime,
                                                       for: notification)

        notification.chat = chat.chatID
        chat.addMessagesObject(notification)
        notification.deliver = "read"
        return (notification, isNewNotification)
    }

    public func createEncryptionNotificationFrom(dictionary: [String: Any],
                                                 inChat chat: Dialog) -> (Message, Bool)? {
        guard let packetID = dictionary["packetId"] as? Int,
              let model = dictionary["model"] as? [String: Any?] else { return nil }

        let actionUserDictionary = model["actionUser"] as? [String: Any] ?? [:]
        let actionUserID = actionUserDictionary["userId"] as? String
        let ownerID = CoreDataFacade.sharedInstance().getOwner().ownerID
        let isOwnerAction = (actionUserID != nil && actionUserID! == ownerID)
        let actionUserName = (actionUserDictionary["name"] as? String) ?? "unknown_user".localized
        let encryptionStatus: Bool
        if let key = model["encrKey"] as? String, !key.isEmpty { encryptionStatus = true }
        else { encryptionStatus = false }

        let notificationText: String

        let actionType = encryptionStatus ? "keychat_enable" : "keychat_disable"

        if isOwnerAction {
            if encryptionStatus {notificationText = "notify_you_enabled_encryption".localized}
            else {notificationText = "notify_you_disabled_encryption".localized}
        } else {
            let phraseTemplate: String
            if encryptionStatus {phraseTemplate = "notify_user_%@_enabled_encryption".localized}
            else { phraseTemplate = "notify_user_%@_disabled_encryption".localized}
            notificationText = String(format: phraseTemplate, actionUserName)
        }

        let notification = self.createNotificationWith(data: dictionary,
                                                       text: notificationText,
                                                       users: nil,
                                                       actionUserID: actionUserID ?? "",
                                                       actionUserName: actionUserName,
                                                       actionType: actionType,
                                                       notificationType: "KEYCHAT",
                                                       packetID: packetID.description,
                                                       chat:chat)
        return notification
    }
}
