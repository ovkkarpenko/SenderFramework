//
//  MWCometParser.swift
//  SENDER
//
//  Created by Eugene Gilko on 5/30/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

public struct MessagesParsingResult {
    let updatedMessages: [Message]
    let addedMessages: [Message]
    let addedGaps: [MessagesGap]
    var forceOpenChatID: String?
}

extension SenderCore: MWCometParserForceOpenHandler {
    @objc public func cometParser(_ parser: MWCometParser, didReceiveForceOpenFormWith chatID: String) {
        _ = self.senderUI?.showChatScreenWith(chatID: chatID,
                                              actions: nil,
                                              options: nil,
                                              animated: true,
                                              modally: false,
                                              delegate: nil)
    }
}

extension SenderCore: MWCometParserSoundPlayer {
    @objc public func cometParser(_ parser: MWCometParser,
                                  didReceiveMessage message: Message,
                                  withData data: [String: AnyObject]) {
        if !message.owner {
            if message.dialog.unreadCount.intValue > 0,
               message.dialog.dialogSetting().muteChatNotification == .disabled {

                var alertType: MWAlertType? = .message

                if message.type == "FORM" {
                    if let state = (data["model"] as? [String: AnyObject])?["state"] as? String {
                        if state == "transaction" {
                            alertType = .money
                        } else if state == "mute" {
                            alertType = nil
                        }
                    }
                }

                if message.linkID != message.packetID { alertType = nil }
                if let alertType = alertType { MWAlertFacade.sharedInstance().performAlert(of: alertType) }
            }
        }
    }
}

@objc public protocol MWCometParserAuthorizationHandler: class {
    @objc func cometParser(_ parser: MWCometParser, didReceiveAuthorizationMessage message: [String: Any])
}

@objc public protocol MWCometParserForceOpenHandler: class {
    @objc func cometParser(_ parser: MWCometParser, didReceiveForceOpenFormWith chatID: String)
}

@objc public protocol MWCometParserSoundPlayer: class {
    @objc func cometParser(_ parser: MWCometParser,
                           didReceiveMessage message: Message,
                           withData data: [String:AnyObject])
}

@objc open class MWCometParser: NSObject {

    @objc public static let shared = MWCometParser()
    @objc public weak var authorizationHandler: MWCometParserAuthorizationHandler?
    @objc public weak var forceOpenHandler: MWCometParserForceOpenHandler?
    @objc public weak var soundPlayer: MWCometParserSoundPlayer?
    @objc public var chatEditManager: ChatEditManager

    @objc override init() {
        let chatBuildManager = ChatBuildManager.buildDefaultChatBuildManager()
        let chatEditManagerInput = ChatEditManagerInput()
        chatEditManager = ChatEditManager(input: chatEditManagerInput, chatBuildManager: chatBuildManager)
        super.init()
    }

    @objc open func parseCometResponseArray(_ fsArray: [[String:AnyObject]]) {

        print("\nPARSE: \n")
        print(fsArray)

        var sysArray = [[String: AnyObject]]()

        var parseArray = [[String: AnyObject]]()

        for fsItem: [String: AnyObject] in fsArray {
            if let chatID = fsItem["chatId"] as? String {
                if chatID == "@sys" {
                    sysArray.append(fsItem)
                } else {
                    parseArray.append(fsItem)
                }
            }
        }

        sysArray.forEach { self.routeSysID($0) }
        parseArray.forEach {
            guard let parsingResult = self.routeMsgItem($0, isFromHistory: false) else { return }
            SenderCore.shared().interfaceUpdater.messagesWereUpdated(parsingResult.updatedMessages)
            SenderCore.shared().interfaceUpdater.messagesWereAdded(parsingResult.addedMessages)
            SenderCore.shared().interfaceUpdater.messagesGapsWereAdded(parsingResult.addedGaps)

            if let forceOpenChatID = parsingResult.forceOpenChatID {
                let forceOpenHandler = self.forceOpenHandler ?? SenderCore.shared()
                forceOpenHandler.cometParser(self, didReceiveForceOpenFormWith: forceOpenChatID)
            }
        }
    }

    open func parseHistoryResponse(_ msgItem: [String:AnyObject]) -> MessagesParsingResult? {
        return self.routeMsgItem(msgItem,
                                 isFromHistory: true)
    }

    fileprivate func routeSysID(_ sysItem: [String:AnyObject]) {
        guard let systemMessages = sysItem["msgs"] as? [[String: AnyObject]] else { return }
        for sysMessage in systemMessages {
            guard let classString = sysMessage["class"] as? String else { continue }
            switch classString {
            case "callState": self.wCallState(sysMessage)
                break
            case "proxySend": self.wProxySend(sysMessage)
                break
            case "checkStatus": self.wCheckUserStatus(sysMessage)
                break
            case "startSyncCt": self.wStartSyncContacts(sysMessage)
                break
            case "getSelfInfo": self.wGetSelfInfo(sysMessage)
                break
            case "checkUserStatus": self.wCheckUserStatus(sysMessage)
                break
            case "authNative": self.wAuthNative(sysMessage)
                break
            case "forceOpen": self.wForceOpen(sysMessage, chat: nil)
                break
            case "ip": self.wIp(sysMessage)
                break
            case "setCt": self.wSetCt(sysMessage)
                break
            case "updChat": self.wUpdChat(sysMessage)
                break
            case "chatOptionsSet": self.wChatOptionsSet(sysMessage)
                break
            case "updateStorage": self.wUpdateStorage(sysMessage)
                break
            case "oStatusInfo": self.wOStatusInfo(sysMessage)
                break
            case "oChatList": self.wOChatList(sysMessage)
                break
            case "oChatSet": self.wOChatSet(sysMessage)
                break
            case "oChatDel": self.wOChatDel(sysMessage)
                break
            case "oChatSetTime": self.wOChatSetTime(sysMessage)
                break
            case "typing": self.wTyping(sysMessage)
                break
            case "oTyping": self.wOTyping(sysMessage)
                break
            default:
                break
            }
        }
    }

    fileprivate func routeMsgItem(_ msgItem: [String:AnyObject],
                                  isFromHistory: Bool = false) -> MessagesParsingResult? {

        guard let chatID = msgItem["chatId"] as? String else { return nil }

        /*
            It's possible that we receive only status or unread messages count updates for deleted chats.
            For such cases there is no need to create chat.
         */

        let hasMessages = msgItem["msgs"] is [[String:AnyObject]]
        let chatExists = CoreDataFacade.sharedInstance().dialog(withChatIDIfExist: chatID) != nil

        /*
             It's possible that after leaving and deleting chat model we will receive visual notification.
             We should ignore this notification, otherwise deleted chat will be created again.

             Hope, some day it'll be fixed on server side
         */
        let ignoreMessages = !chatExists && self.shouldIgnoreMessages(msgItem)

        guard !ignoreMessages && (hasMessages || chatExists) else { return nil }

        let chat = self.chatEditManager.chatWith(chatID: chatID)
        guard !chat.isBlocked() else { return nil }

        var addedMessages = [Message]()
        var updatedMessages = [Message]()
        var addedGaps = [MessagesGap]()

        var forceOpenChatID: String?

        if let messages = msgItem["msgs"] as? [[String:AnyObject]] {
            var needLoadMoreMessages: Bool = false

            if let more = msgItem["more"] as? Bool { if more { needLoadMoreMessages = true }}

            for (index, regMessage) in messages.enumerated() {
                if index == (messages.count - 1) && needLoadMoreMessages {
                    if let startPacketID = regMessage["packetId"] as? Int {
                        let endPacketID: Int
                        let messageIndex = chat.indexOfMessage(withPacketID: startPacketID)
                        if messageIndex == 0 {
                            endPacketID = 0
                        } else {
                            let previousMessageIndex = (messageIndex > 0) ? messageIndex - 1 : 0
                            let previousPacketID = chat.packetIDOfMessage(at: previousMessageIndex)
                            endPacketID = previousPacketID != NSNotFound ? previousPacketID : 0
                        }

                        let creationTime = regMessage["created"] as? TimeInterval ?? Date().timeIntervalSince1970 * 1000
                        if let gap = CoreDataFacade.sharedInstance().addGap(withStartPacketID: startPacketID,
                                                                            endPacketID: endPacketID,
                                                                            creationTime: creationTime,
                                                                            toChat: chat) {
                            addedGaps.append(gap)
                        }
                    }
                }

                var shouldBuildMessage = true
                if  let messageClass = regMessage["class"] as? String,
                    messageClass == "ntfChat",
                    let messageType = (regMessage["model"] as? [String: Any])?["type"] as? String,
                    messageType != "add",
                    !chatExists {
                    shouldBuildMessage = false
                }

                if isFromHistory {
                    /*
                     * New messages without "created" will be displayed in the bottom of chat
                     * It's critical when it's message from history
                     * So we parse messages without "created" from history only if it's a message update
                     * and we have an original message in the same packet of messages, we get a message update from
                     */
                    if regMessage["created"] == nil {
                        if let linkID = regMessage["linkId"] as? Int {
                            if messages.filter({ ($0["packetId"] as? Int) == linkID }).first == nil {
                                shouldBuildMessage = false
                            }
                        } else {
                            shouldBuildMessage = false
                        }
                    }
                }

                if shouldBuildMessage {
                    if let newMessage = self.wBuildRegularMessage(regMessage, chat: chat) {
                        let isNewMessage = newMessage.1
                        if isNewMessage {
                            addedMessages.append(newMessage.0)
                        } else {
                            updatedMessages.append(newMessage.0)
                        }

                        if let messageModel = regMessage["model"] as? [String: AnyObject],
                           let forceOpen = messageModel["forceOpen"],
                           let chatID = chat.chatID ?? (regMessage["model"] as? [String: Any])?["chatId"] as? String {
                            if let mode = forceOpen as? String {
                                if mode.toBool() { forceOpenChatID = chatID }
                            } else if let mode = forceOpen as? NSNumber {
                                if mode.intValue > 0 { forceOpenChatID = chatID }
                            }
                        }
                    }
                }
            }
        }

        var shouldUpdateChat = false
        /*
         * Setting last message status
         */
        let statusUnparsed = msgItem["status"] as? String
        let newStatus = statusUnparsed != nil ? messageStatusFromString(statusUnparsed!) : .sent
        if newStatus != chat.lastMessageStatus {
            chat.lastMessageStatus = newStatus
            if let lastMessage = chat.lastMessage,
               !addedMessages.contains(lastMessage),
               !updatedMessages.contains(lastMessage) {
                updatedMessages.append(lastMessage)
            }
            shouldUpdateChat = true
        }

        /*
         * Set chat counter
         */
        let newUnreadCount: Int

        if let ntfCounter = chat.chatSettings?.ntfCounter, ntfCounter == "off" {
            newUnreadCount = msgItem["unread"] as? Int ?? 0
        } else {
            newUnreadCount = 0
        }

        if newUnreadCount != chat.unreadCount.intValue {
            chat.unreadCount = NSNumber(value: newUnreadCount)
            shouldUpdateChat = true
        }

        if shouldUpdateChat {
            SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
        }

        return MessagesParsingResult(updatedMessages: updatedMessages,
                                     addedMessages: addedMessages,
                                     addedGaps: addedGaps,
                                     forceOpenChatID: forceOpenChatID)
    }

    private func shouldIgnoreMessages(_ msgItem: [String:AnyObject]) -> Bool {
        var ignoreMessages = false
        if let messagesDictionaries = msgItem["msgs"] as? [[String:AnyObject]],
           let message = messagesDictionaries.first, messagesDictionaries.count == 1 {
            let ownerUserID = CoreDataFacade.sharedInstance().getOwner().ownerID
            if message["class"] as? String  == "ntfChat",
               let model = message["model"] as? [String: Any],
               let notificationType = model["type"] as? String {
                if notificationType == "leave" {
                    let actionUserID = (model["actionUser"] as? [String: Any])?["userId"] as? String
                    ignoreMessages = actionUserID == ownerUserID
                } else if notificationType == "del" {
                    if let users = model["users"] as? [[String: Any]] {
                        let ownerUsers = users.filter({($0["userId"] as? String) == ownerUserID})
                        ignoreMessages = !ownerUsers.isEmpty
                    }
                }
            }
        }
        return ignoreMessages
    }

    fileprivate func getContact(_ userID: String) -> Contact? {
        return CoreDataFacade.sharedInstance().selectContact(byId: userID) as? Contact
    }
    // @sys workers

    fileprivate func wCallState(_ sysMsg: [String:AnyObject]) {
        //to do
    }

    fileprivate func wProxySend(_ sysMsg: [String:AnyObject]) {
        // unused
    }

    fileprivate func wStartSyncContacts(_ sysMsg: [String:AnyObject]) {
        let fullVersionEnabled = ((sysMsg["model"] as? [String: AnyObject])?["sync_user_ct"] as? Bool) ?? true
        if fullVersionEnabled == SenderCore.shared().isFullVersionEnabled {
            SenderCore.shared().startSynchronization(nil)
        } else {
            SenderCore.shared().changeFullVersionState(fullVersionEnabled, completion: nil)
        }
    }

    fileprivate func wGetSelfInfo(_ sysMsg: [String:AnyObject]) {
        CoreDataFacade.sharedInstance().setOwnerInfo(sysMsg["model"] as! [AnyHashable: Any])
        do {
            if let pMsgKey = sysMsg["msgKey"] as? String {
                if try pMsgKey == CoreDataFacade.sharedInstance().getOwner().getMainWallet().base58PublicKey {
                    ServerFacade.sharedInstance().checkStorageWallet()
                }
            }
        } catch {
            // BOOM!!!
        }
    }

    fileprivate func wCheckUserStatus(_ sysMsg: [String:AnyObject]) {
        guard let messageModel = sysMsg["model"] as? [String: AnyObject],
              let userID = messageModel["userId"] as? String,
              let user = self.getContact(userID) else { return }

        if let status = messageModel["status"] as? String {
            user.isOnline = NSNumber(value: status != "offline")
        }
        SenderCore.shared().interfaceUpdater.onlineStatusWasChangedForContacts([user])
    }

    fileprivate func wAuthNative(_ sysMsg: [String:Any]) {
        DispatchQueue.main.async {
            self.authorizationHandler?.cometParser(self, didReceiveAuthorizationMessage: sysMsg)
        }
    }

    fileprivate func wForceOpen(_ sysMsg: [String:AnyObject], chat: Dialog?) {
        guard let chatID = chat?.chatID ?? (sysMsg["model"] as? [String: AnyObject])?["chatId"] as? String else {
            return
        }
        let forceOpenHandler = self.forceOpenHandler ?? SenderCore.shared()
        forceOpenHandler.cometParser(self, didReceiveForceOpenFormWith: chatID)
    }

    fileprivate func wIp(_ sysMsg: [String:AnyObject]) {
        SenderRequestBuilder.sharedInstance().gotNewIP(sysMsg["model"] as! [AnyHashable: Any])
    }

    fileprivate func wSetCt(_ sysMsg: [String:AnyObject]) {
        guard let model = sysMsg["model"] as? [String: Any],
              let userDictionaries = model["cts"] as? [[String: Any]] else { return }

        _ = self.chatEditManager.handleChatsInfo(userDictionaries)
    }

    fileprivate func wUpdChat(_ sysMsg: [String:AnyObject]) {
        guard let model = sysMsg["model"] as? [String: Any],
              let chatDictionaries = model["chatList"] as? [[String: Any]] else { return }

        _ = self.chatEditManager.handleChatsInfo(chatDictionaries)
    }

    fileprivate func wChatOptionsSet(_ sysMsg: [String:AnyObject]) {
        guard let model = sysMsg["model"] as? [String: Any] else { return }

        _ = self.chatEditManager.handleChatSettingsDictionary(model)
    }

    fileprivate func wUpdateStorage(_ sysMsg: [String:AnyObject]) {
        if SenderCore.shared().isBitcoinEnabled {
            ServerFacade.sharedInstance().checkStorageWallet()
        }
    }

    fileprivate func wTyping(_ sysMsg: [String:AnyObject]) {
        if  let messageModel = sysMsg["model"] as? [String: Any],
            let chatID = messageModel["chatId"] as? String,
            let userID = messageModel["from"] as? String,
            let contact = self.getContact(userID) {
            SENDER_SHARED_CORE.interfaceUpdater.contactsStartedTyping([contact], inChat: chatID)
        }
    }

    /* UNUSED */
    fileprivate func wOStatusInfo(_ sysMsg: [String:AnyObject]) {
        // change status online=offline
    }

    fileprivate func wOChatList(_ sysMsg: [String:AnyObject]) {

    }

    fileprivate func wOChatSet(_ sysMsg: [String:AnyObject]) {

    }

    fileprivate func wOChatDel(_ sysMsg: [String:AnyObject]) {

    }

    fileprivate func wOChatSetTime(_ sysMsg: [String:AnyObject]) {

    }

    fileprivate func wOTyping(_ sysMsg: [String:AnyObject]) {

    }
    /* UNUSED */
    // @messages workers

    fileprivate func wBuildRegularMessage(_ regMsg: [String:AnyObject], chat: Dialog) -> (Message, Bool)? {

        let viewModel = regMsg["view"] as? [String:AnyObject]
        var newMessage: (Message, Bool)? = nil
        if viewModel != nil && viewModel!.count > 0 {
            // build form
            if let formClass = regMsg["class"] as? String,
               let robotID = classComponentsFrom(classString: formClass).robotID,
               robotID == "contact" {
                let companyCardResult = self.addCompanyCardFrom(dictionary: regMsg, toChat: chat)
                newMessage = (companyCardResult.0 as Message, companyCardResult.1)
            } else {
                newMessage = self.messageWorker(regMsg, chat: chat)
            }
        } else if let type = regMsg["class"] as? String {
            switch type {
            case "text", "image", "audio", "file", "location", "sticker", "vibro", "video":
                newMessage = self.messageWorker(regMsg, chat: chat)
            case "ntfChat":
                newMessage = notificationWorker(regMsg, chat: chat)
            case "keyChat":
                newMessage = self.setChatKey(regMsg, chat: chat)
            default:
                break
            }
        }
        return newMessage
    }

    fileprivate func addCompanyCardFrom(dictionary: [String: Any], toChat chat: Dialog) -> (CompanyCard, Bool) {
        return MWMessageCreator.shared.companyCardWith(dictionary: dictionary, chat: chat)
    }

    fileprivate func messageWorker(_ regMsg: [String:AnyObject], chat: Dialog) -> (Message, Bool)? {
        guard chat.chatID != nil else { return nil }
        guard let newMessage = MWMessageCreator.shared.setMessageDataFromInfo(regMsg, chat: chat) else { return nil }
        let soundPlayer = self.soundPlayer ?? SenderCore.shared()
        soundPlayer.cometParser(self, didReceiveMessage: newMessage.0, withData: regMsg)
        return newMessage
    }

    fileprivate func notificationWorker(_ regMsg: [String:AnyObject], chat: Dialog) -> (Message, Bool)? {
        return MWNotificationCreator.shared.setNotificationMessageFromInfo(regMsg,
                                                                           chat: chat)
    }

    fileprivate func setChatKey(_ regMsg: [String:AnyObject], chat: Dialog) -> (Message, Bool)? {
        let notification = MWNotificationCreator.shared.createEncryptionNotificationFrom(dictionary: regMsg,
                                                                                            inChat: chat)
        _ = self.chatEditManager.handleChatKey(regMsg, forChat: chat)
        return notification
    }
}
