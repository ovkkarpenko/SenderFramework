//
// Created by Roman Serga on 14/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(ChatEditManagerInputProtocol)
public protocol ChatEditManagerInputProtocol {

    func getInfoFor(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler)

    func addMembersWith(userIDs: [String],
                        toChatWithID chatID: String,
                        requestHandler: @escaping SenderRequestCompletionHandler)

    func leaveChatWith(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler)

    func edit(chatID: String,
              withName name: String?,
              description: String?,
              imageURL: String?,
              requestHandler: @escaping SenderRequestCompletionHandler)

    func uploadChatImageData(_ imageData: Data, completion: @escaping ((URL?, Error?) -> Void))

    func sendReadFor(message: Message)

    func saveP2PChatWith(userID: String, requestHandler: @escaping SenderRequestCompletionHandler)
    func deleteP2PChatWith(userID: String, requestHandler: @escaping SenderRequestCompletionHandler)
    func changeP2PChatWith(userID: String,
                           name: String?,
                           phone: String?,
                           requestHandler: @escaping SenderRequestCompletionHandler)

    func changeSettingsOfChatWith(chatID: String,
                                  settingsDictionary: [String: Any],
                                  requestHandler: @escaping SenderRequestCompletionHandler)

    func changeChatEncryptionStateWith(chatID: String,
                                       encryptionState: Bool,
                                       keys: [String: String]?,
                                       senderKey: String?,
                                       requestHandler: @escaping SenderRequestCompletionHandler)

    func deleteMembersWith(userIDs: [String],
                           toChatWithID chatID: String,
                           requestHandler: @escaping SenderRequestCompletionHandler)
}

@objc(MWChatSettingsEditModel)
public class ChatSettingsEditModel: NSObject {

    @objc public var isFavorite: Bool
    @objc public var isBlocked: Bool
    @objc public var soundScheme: ChatSettingsSoundScheme
    @objc public var muteChatNotification: ChatSettingsNotificationType
    @objc public var hidePushNotification: ChatSettingsNotificationType
    @objc public var smartPushNotification: ChatSettingsNotificationType
    @objc public var hideTextNotification: ChatSettingsNotificationType
    @objc public var hideCounterNotification: ChatSettingsNotificationType

    @objc public var settingsDictionary: [String: Any] {
        var notificationSettings = [String: String]()
        notificationSettings["m"] = stringFromChatSettingsNotificationType(muteChatNotification)
        notificationSettings["h"] = stringFromChatSettingsNotificationType(hidePushNotification)
        notificationSettings["s"] = stringFromChatSettingsNotificationType(smartPushNotification)
        notificationSettings["t"] = stringFromChatSettingsNotificationType(hideTextNotification)
        notificationSettings["c"] = stringFromChatSettingsNotificationType(hideCounterNotification)

        var postParameters: [String: Any] = ["ntf": notificationSettings]
        postParameters["block"] = self.isBlocked
        postParameters["fav"] = self.isFavorite
        postParameters["snd"] = stringFromChatSettingsSoundScheme(soundScheme)

        return postParameters
    }

    @objc public init(chatSettings: DialogSetting) {
        self.isFavorite = chatSettings.favChat.boolValue
        self.isBlocked = chatSettings.blockChat.boolValue
        self.soundScheme = chatSettings.chatSoundScheme
        self.muteChatNotification = chatSettings.muteChatNotification
        self.hidePushNotification = chatSettings.hidePushNotification
        self.smartPushNotification = chatSettings.smartPushNotification
        self.hideTextNotification = chatSettings.hideTextNotification
        self.hideCounterNotification = chatSettings.hideCounterNotification

        super.init()
    }
}

@objc(MWChatEditManager)
public class ChatEditManager: NSObject {

    public typealias ChatEditManagerCompletion = ((Dialog?, Error?) -> Void)

    @objc public let input: ChatEditManagerInputProtocol
    @objc public let chatBuildManager: ChatBuildManagerProtocol

    @objc public init(input: ChatEditManagerInputProtocol, chatBuildManager: ChatBuildManagerProtocol) {
        self.input = input
        self.chatBuildManager = chatBuildManager

        super.init()
    }

    //MARK : - Updating Chat Info

    @objc public func update(chat: Dialog, completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot get chat info. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        self.updateChatWith(chatID: chatID, completionHandler: completionHandler)
    }

    private func updateChatWith(chatID: String, completionHandler: ChatEditManagerCompletion?) {
        self.input.getInfoFor(chatID: chatID) { response, error in

            guard error == nil else { completionHandler?(nil, error); return }

            guard let chatInfoDictionary = response?["chat"] as? [String: Any] else {
                let error = NSError(domain: "Cannot get chat info. Server error", code: 1)
                completionHandler?(nil, error)
                return
            }

            do {
                let updatedChat = try self.chatBuildManager.chatWith(dictionary: chatInfoDictionary,
                                                                     isNewChat: nil)
                SenderCore.shared().interfaceUpdater.chatsWereChanged([updatedChat])
                completionHandler?(updatedChat, nil)
            } catch let error as NSError {
                completionHandler?(nil, error)
            }
        }
    }

    //MARK : - Changing Chat

    @objc public func add(members: [Dialog],
                          toChat chat: Dialog,
                          completionHandler: ChatEditManagerCompletion?) {
        let userIds = members.flatMap({return userIDFromChatID($0.chatID) })
        guard !userIds.isEmpty else {
            let error = NSError(domain: "Cannot create chat. No users with valid userID", code: 1)
            completionHandler?(nil, error)
            return
        }
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot create chat. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        self.input.addMembersWith(userIDs: userIds, toChatWithID: chatID) { response, error in

            guard error == nil else { completionHandler?(nil, error); return }

            guard let chatInfoDictionary = response?["chatInfo"] as? [String: Any] else {
                let error = NSError(domain: "Cannot create chat. Server error", code: 1)
                completionHandler?(nil, error)
                return
            }

            do {
                let newChat = try self.chatBuildManager.chatWith(dictionary: chatInfoDictionary,
                                                                 isNewChat: nil)
                SenderCore.shared().interfaceUpdater.chatsWereChanged([newChat])
                if SenderCore.shared().isBitcoinEnabled, newChat.isGroup, newChat.isEncrypted() {
                    self.setEncryptionStateOf(chat: newChat,
                                              encryptionState: newChat.isEncrypted()) {chat, error in
                        /*
                            We get here after successfully adding members to chat.
                            So, chat model must be with new members.
                            That's why we return changed chat
                            even if we got error after resetting encryption keys.
                         */
                        let resultChat = chat ?? newChat
                        completionHandler?(resultChat, error)
                    }
                } else {
                    completionHandler?(newChat, nil)
                }
            } catch let error as NSError {
                completionHandler?(nil, error)
            }
        }
    }

    /*
        Method may return both chat and error in completionHandler. It may happen
        if deleting member was successful, but keys resetting wasn't.
     */
    @objc public func deleteMembers(_ members: [ChatMember],
                                    ofChat chat: Dialog,
                                    completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot change encryption state. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        let membersIDs = members.flatMap({ return $0.contact.userID })

        self.input.deleteMembersWith(userIDs: membersIDs,
                                     toChatWithID: chatID) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }

            guard let chatInfoDictionary = response?["chatInfo"] as? [String: Any] else {
                let error = NSError(domain: "Cannot delete member. Server error", code: 1)
                completionHandler?(nil, error)
                return
            }

            do {
                let newChat = try self.chatBuildManager.chatWith(dictionary: chatInfoDictionary,
                                                                 isNewChat: nil)
                SenderCore.shared().interfaceUpdater.chatsWereChanged([newChat])
                if SenderCore.shared().isBitcoinEnabled, newChat.isGroup, newChat.isEncrypted() {
                    self.setEncryptionStateOf(chat: newChat,
                                              encryptionState: newChat.isEncrypted()) {chat, error in
                        /*
                            We get here after successfully deleting member from chat.
                            So, chat model must be without member we deleted.
                            That's why we return changed chat even if we got error after resetting encryption keys.
                        */
                        let resultChat = chat ?? newChat
                        completionHandler?(resultChat, error)
                    }
                } else {
                    completionHandler?(newChat, nil)
                }
            } catch let error as NSError {
                completionHandler?(nil, error)
            }
        }
    }

    @objc public func leave(chat: Dialog,
                            completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot leave chat. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        chat.unreadCount = 0
        if let lastMessage = chat.lastMessage {
            self.input.sendReadFor(message: lastMessage)
        }

        self.input.leaveChatWith(chatID: chatID) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }
            //            self.chatBuildManager.delete(chat: chat)
            //            SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
            completionHandler?(chat, nil)
        }
    }

    /*
        Using nil as name/description/imageData means "don't change this parameter".
        To delete name/description use "". To delete image, use empty image data
     */
    @objc public func edit(chat: Dialog,
                           withName name: String?,
                           description: String?,
                           imageData: Data?,
                           completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot edit chat. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        let editClosure: (String) -> Void
        editClosure = { imageURLString in
            self.input.edit(chatID: chatID,
                            withName: name,
                            description: description,
                            imageURL: imageURLString) { response, error in
                guard error == nil else { completionHandler?(nil, error); return }
                completionHandler?(chat, nil)
            }
        }

        if let imageData = imageData {
            if !imageData.isEmpty {
                self.input.uploadChatImageData(imageData) { imageURL, error in
                    guard let url = imageURL else {
                        let error = NSError(domain: "Cannot get image URL. Server error", code: 1)
                        completionHandler?(nil, error)
                        return
                    }
                    editClosure(url.absoluteString)
                }
            } else {
                editClosure("")
            }
        } else {
            editClosure(chat.imageURL ?? "")
        }
    }

    /*
        Using nil as name/phone means "don't change this parameter". To delete name/phone use "".
     */
    @objc public func edit(p2pChat: Dialog,
                           withName name: String?,
                           phone: String?,
                           completionHandler: ChatEditManagerCompletion?) {
        guard let userID = userIDFromChatID(p2pChat.chatID) else {
            let error = NSError(domain: "Cannot change chat. Wrong p2p chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        self.input.changeP2PChatWith(userID: userID,
                                     name: name,
                                     phone: phone) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }

            guard let userInfo = response?["cts"] as? [[String: Any]] else {
                let error = NSError(domain: "Cannot edit chat. Server error", code: 1)
                completionHandler?(nil, error)
                return
            }

            _ = self.handleChatsInfo(userInfo)
            completionHandler?(p2pChat, nil)
        }
    }

    @objc public func delete(chat: Dialog, completionHandler: ChatEditManagerCompletion?) {

        let finishDeleting = {
            SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
            completionHandler?(chat, nil)
        }

        if chat.isP2P, let userID = userIDFromChatID(chat.chatID) {
            self.input.deleteP2PChatWith(userID: userID) { response, error in
                guard error == nil else {
                    completionHandler?(nil, error);
                    return
                }

                guard let userInfo = response?["cts"] as? [[String: Any]] else {
                    let error = NSError(domain: "Cannot delete chat. Server error", code: 1)
                    completionHandler?(nil, error)
                    return
                }
                _ = self.handleChatsInfo(userInfo)
                finishDeleting()
            }
        } else {
            chat.chatState = .removed
            finishDeleting()
        }
    }

    @objc public func save(p2pChat: Dialog, completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = p2pChat.chatID else {
            let error = NSError(domain: "Cannot save chat. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        guard let userID = userIDFromChatID(chatID) else {
            let error = NSError(domain: "Cannot save chat. Wrong chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        self.input.saveP2PChatWith(userID: userID) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }

            guard let userInfo = response?["cts"] as? [[String: Any]] else {
                let error = NSError(domain: "Cannot save p2p chat. Server error", code: 1)
                completionHandler?(nil, error)
                return
            }

            _ = self.handleChatsInfo(userInfo)
            completionHandler?(p2pChat, nil)
        }
    }

    @objc public func changeSettingsOf(chat: Dialog,
                                       newSettings: ChatSettingsEditModel,
                                       completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot change settings. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        self.input.changeSettingsOfChatWith(chatID: chatID,
                                            settingsDictionary: newSettings.settingsDictionary) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }
            completionHandler?(chat, nil)
        }

    }

    @objc public func setEncryptionStateOf(chat: Dialog,
                                           encryptionState: Bool,
                                           completionHandler: ChatEditManagerCompletion?) {
        guard let chatID = chat.chatID else {
            let error = NSError(domain: "Cannot change encryption state. No chatID", code: 1)
            completionHandler?(nil, error)
            return
        }

        let ownerWallet = try? CoreDataFacade.sharedInstance().getOwner().getMainWallet()
        let senderKey = ownerWallet?.base58PublicKey
        var keysDictionary: [String: String]? = nil

        let keyData: Data?

        if encryptionState {
            guard let ownerID = CoreDataFacade.sharedInstance().ownerUDIDString else {
                let error = NSError(domain: "Cannot enable encryption. Owner doesn't have userID", code: 1)
                completionHandler?(nil, error)
                return
            }

            guard let ownerPublicKey = ownerWallet?.rootKey else {
                let error = NSError(domain: "Cannot enable encryption. Owner's wallet doesn't have rootKey", code: 1)
                completionHandler?(nil, error)
                return
            }

            keyData = SecGenerator.sharedInstance().generateAES128Key()
            let tempKey = BTCBase58StringWithData(keyData)

            keysDictionary = [String: String]()
            for member in chat.membersContacts() {
                if let userID = member.userID, userID != ownerID, let btcKey = member.p2pChat?.encryptionKey {
                    let userKey = ECCWorker.shared().eciesEncriptMEssage(tempKey,
                                                                         withPubKeyData: btcKey,
                                                                         shortkEkm: true,
                                                                         usePubKey: false)
                    keysDictionary?[userID] = userKey
                }
            }

            let ownerKey = ECCWorker.shared().eciesEncriptMEssage(tempKey,
                                                                  withPubKey: ownerPublicKey,
                                                                  shortkEkm: true,
                                                                  usePubKey: false)

            keysDictionary?[ownerID] = ownerKey
        } else {
            keyData = nil
        }

        self.input.changeChatEncryptionStateWith(chatID: chatID,
                                                 encryptionState: encryptionState,
                                                 keys: keysDictionary,
                                                 senderKey: senderKey) { response, error in
            guard error == nil else { completionHandler?(nil, error); return }

            chat.encryptionKey = keyData
            chat.setGroupEncryptionState(encryptionState)

            SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
            completionHandler?(chat, nil)
        }
    }

    //MARK : - Getting Chat By ID

    @objc public func chatWith(chatID: String) -> Dialog {
        let isNewChat = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        let chat = self.chatBuildManager.chatWith(chatID: chatID,
                                                  isNewChat: isNewChat)
        if isNewChat.pointee {
            self.update(chat: chat, completionHandler: nil)
        }
        return chat
    }

    //MARK : - Handling Chat Changes

    @objc public func handleChatsInfo(_ chatsInfo: [[String: Any]]) -> [Dialog] {
        let updatedChats: [Dialog] = chatsInfo.flatMap({
            /*
                Chat info can be either userInfo either old chatInfo or new chatInfo.
            */
            var chatInfo = $0
            if isUserInfoDictionary($0) {
                chatInfo = convertUserInfoToChatInfo($0)
            } else if isOldChatFormat($0) {
                chatInfo = convertOldChatFormatToNewChatInfo($0)
            }
            return try? chatBuildManager.chatWith(dictionary: chatInfo, isNewChat: nil)
        })
        SenderCore.shared().interfaceUpdater.chatsWereChanged(updatedChats)
        return updatedChats
    }

    @objc public func handleChatSettingsDictionary(_ chatSettingsDictionary:[String: Any]) -> Dialog? {
        if let chat = try? chatBuildManager.chatWith(chatSettingsDictionary: chatSettingsDictionary,
                                                     isNewChat: nil) {
            SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
            return chat
        } else {
            return nil
        }
    }

    @objc public func handleChatKey(_ chatKey: [String: Any], forChat chat: Dialog) -> Dialog {

        var oldKeyInfo = false

        /*
            Handling key without packetID as most recent
        */
        if let keysPacketID = chatKey["packetId"] as? Int,
           let lastChatMessage = chat.messages?.lastObject as? Message,
           let lastChatMessagePacketID = Int(lastChatMessage.packetID) {
            if keysPacketID >= lastChatMessagePacketID {} else { oldKeyInfo = true }
        }

        var encKey: String?
        var sendKey: String?
        if let messageModel = chatKey["model"] as? [String: Any] {
            encKey = messageModel["encrKey"] as? String
            sendKey = messageModel["senderKey"] as? String
        }

        chat.setGroupEncryptionKey(encKey, withSenderKey: sendKey, isOldKey: oldKeyInfo)
        SENDER_SHARED_CORE.interfaceUpdater.chatsWereChanged([chat])

        return chat
    }

    //MARK : - Sending Read

    public func sendReadFor(message: Message) {
        guard !message.owner, let chat = message.dialog else { return }
        self.input.sendReadFor(message: message)

        if let foreignMessages = chat.foreignMessages {
            let reversedForeignMessages = Array(foreignMessages.reversed())
            if let newUnreadCount = reversedForeignMessages.index(of: message),
               newUnreadCount < chat.unreadCount.intValue {
                chat.unreadCount = NSNumber(integerLiteral: newUnreadCount)
                SENDER_SHARED_CORE.interfaceUpdater.chatsWereChanged([chat])
            }
        }
    }
}

public extension ChatEditManager {

    @objc public convenience init(input: ChatEditManagerInputProtocol) {
        let chatBuildManager = ChatBuildManager.buildDefaultChatBuildManager()
        self.init(input: input, chatBuildManager: chatBuildManager)
    }
}

//MARK : - Convert Functions

fileprivate func isOldChatFormat(_ dictionary: [String: Any]) -> Bool {
    return (dictionary["chatName"] as? String) != nil ||
            (dictionary["chatPhoto"] as? String) != nil ||
            (dictionary["encrKey"] as? String) != nil
}

fileprivate func isUserInfoDictionary(_ dictionary: [String: Any]) -> Bool {
    return (dictionary["userId"] as? String) != nil
}

fileprivate func isChatSettingsDictionary(_ dictionary: [String: Any]) -> Bool {
    return dictionary["options"] == nil &&
            dictionary["fav"] as? Bool != nil
}

fileprivate func convertUserInfoToChatInfo(_ userInfo: [String: Any]) -> [String: Any] {
    var chatInfo = userInfo

    if let userID = chatInfo["userId"] as? String {
        chatInfo["chatId"] = chatIDFromUserID(userID)
        chatInfo["userId"] = nil
    }

    let isCompany = (chatInfo["isCompany"] as? String  == "true") ?? false
    let chatType: ChatType = isCompany ? .company : .P2P
    chatInfo["isCompany"] = nil
    chatInfo["type"] = stringFromChatType(chatType)

    let isBlocked = chatInfo["isBlocked"] as? Bool
    let isFavorite = chatInfo["isFavorite"] as? Bool

    if isBlocked != nil || isFavorite != nil {
        var chatOptions = [String: Any]()
        if isBlocked != nil { chatOptions["block"] = isBlocked }
        if isFavorite != nil { chatOptions["fav"] = isFavorite }

        chatInfo["options"] = chatOptions
    }

    if let encryptionKey = chatInfo["msgKey"] as? String {
        chatInfo["encryptionKey"] = encryptionKey
        chatInfo["msgKey"] = nil
    }

    return chatInfo
}

fileprivate func convertOldChatFormatToNewChatInfo(_ userInfo: [String: Any]) -> [String: Any] {
    var chatInfo = userInfo

    if let name = chatInfo["chatName"] as? String {
        chatInfo["name"] = name
        chatInfo["chatName"] = nil
    }

    if let photo = chatInfo["chatPhoto"] as? String {
        chatInfo["photo"] = photo
        chatInfo["chatPhoto"] = nil
    }

    if let encryptionKey = chatInfo["encrKey"] as? String {
        chatInfo["encryptionKey"] = encryptionKey
        chatInfo["encrKey"] = nil
    }

    return chatInfo
}

fileprivate func convertChatSettingsToChatInfo(_ chatSettings: [String: Any]) -> [String: Any] {
    var mutableChatSettings = chatSettings
    var chatInfo = [String: Any]()

    if let chatID = mutableChatSettings["id"] as? String {
        chatInfo["chatId"] = chatID
        mutableChatSettings["id"] = nil
    }

    chatInfo["options"] = mutableChatSettings

    return chatInfo
}
