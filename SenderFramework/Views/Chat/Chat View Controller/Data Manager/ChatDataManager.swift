//
// Created by Roman Serga on 2/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatDataManager: ChatEditManager, ChatDataManagerProtocol {

    private weak var messagesChangesHandler: MessagesChangesHandler?
    private weak var messagesGapsChangesHandler: MessagesGapsChangesHandler?
    private weak var chatChangesHandler: ChatsChangesHandler?
    private weak var typingChangesHandler: TypingChangesHandler?

    public func getSenderUsers() -> [Contact] {
        return CoreDataFacade.sharedInstance().getAllContacts()
    }

    public func getContacts() -> [Contact] {
        return CoreDataFacade.sharedInstance().getUsers()
    }

    public func getOwnerBitcoinWallet() -> BitcoinWallet? {
        return try? CoreDataFacade.sharedInstance().getOwner().getMainWallet()
    }

    public func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        var postData = [AnyHashable: Any]()
        postData["formId"] = model.formID ?? ""
        postData["robotId"] = model.robotID ?? ""
        postData["companyId"] = model.companyID ?? ""
        if let userID = model.userID {
            postData["userId"] = userID
        }

        let senderChatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
        ServerFacade.sharedInstance().callRobot(withParameters: postData,
                                                chatID: model.chatID ?? senderChatID,
                                                withModel: model.model,
                                                requestHandler: completion)
    }

    public func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendQR(qrString,
                                             chatID: chatID,
                                             additionalParameters: nil) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }

    public func startMessagesChangesObservingWith(messagesChangesHandler: MessagesChangesHandler) {
        if let oldMessagesChangesHandler = self.messagesChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(oldMessagesChangesHandler)
        }
        self.messagesChangesHandler = messagesChangesHandler
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(messagesChangesHandler)
    }

    public func stopMessagesChangesObserving() {
        if let messagesChangesHandler = self.messagesChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(messagesChangesHandler)
        }
        self.messagesChangesHandler = nil
    }

    public func startChatChangesObservingWith(chatChangesHandler: ChatsChangesHandler) {
        if let oldChatChangesHandler = self.chatChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(oldChatChangesHandler)
        }
        self.chatChangesHandler = chatChangesHandler
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(chatChangesHandler)
    }

    public func stopChatChangesObserving() {
        if let chatChangesHandler = self.chatChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(chatChangesHandler)
        }
        self.chatChangesHandler = nil
    }

    public func startMessagesGapsChangesObservingWith(messagesGapsChangesHandler: MessagesGapsChangesHandler) {
        if let oldMessagesGapsChangesHandler = self.messagesGapsChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(oldMessagesGapsChangesHandler)
        }
        self.messagesGapsChangesHandler = messagesGapsChangesHandler
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(messagesGapsChangesHandler)
    }

    public func stopMessagesGapsChangesObserving() {
        if let messagesGapsChangesHandler = self.messagesGapsChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(messagesGapsChangesHandler)
        }
        self.messagesGapsChangesHandler = nil
    }

    public func startTypingObservingWith(typingChangesHandler: TypingChangesHandler) {
        if let oldTypingChangesHandler = self.typingChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(oldTypingChangesHandler)
        }
        self.typingChangesHandler = typingChangesHandler
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(typingChangesHandler)
    }

    public func stopTypingChangesObserving() {
        if let typingChangesHandler = self.typingChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(typingChangesHandler)
        }
        self.typingChangesHandler = nil
    }

    public func loadHistoryWith(chatID: String, topPacketID: Int,
                                messagesCount: UInt,
                                completion: ((MessagesParsingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().loadHistoryOfChat(withID: chatID,
                                                        startingWithPacketID: topPacketID,
                                                        messagesCount: messagesCount) { (response, error) in
            guard let response = response as? [String: AnyObject], error == nil else {
                completion?(nil, error)
                return
            }
            let parsingResult = MWCometParser.shared.parseHistoryResponse(response)
            completion?(parsingResult, nil)
        }
    }

    public func loadHistoryWith(chatID: String,
                                startPacketID: Int,
                                endPacketID: Int,
                                completion: ((MessagesParsingResult?, Error?) -> Void)?) {
        let isWWANInternet = ServerFacade.sharedInstance().isWwan()
        ServerFacade.sharedInstance().loadHistoryOfChat(withID: chatID,
                                                        startingWithPacketID: startPacketID,
                                                        endPacketID: endPacketID,
                                                        messagesCount: isWWANInternet ? 20 : 50) { (response, error) in
            guard let response = response as? [String: AnyObject], error == nil else {
                completion?(nil, error)
                return
            }
            let parsingResult = MWCometParser.shared.parseHistoryResponse(response)
            completion?(parsingResult, nil)
        }
    }

    public func sendTypingTo(chat: Dialog) {
        guard let chatID = chat.chatID else { return }
        ServerFacade.sharedInstance().sendTypingToChat(withID: chatID, requestHandler:nil)
    }

    public func sendFormData(_ formData: [AnyHashable: Any], completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendForm(formData) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }

    public func changeFullVersionStateTo(newFullVersionState: Bool, completion: ((Bool, Error?) -> Void)?) {
        SenderCore.shared().changeFullVersionState(newFullVersionState) { error in
            let success = error == nil
            completion?(success, error)
        }
    }

    public func uploadData(_ data: Data, completion: ((URL?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().uploadData(data,
                                                 withFileExtension: "jpg",
                                                 target: "upload",
                                                 additionalData: nil) { response, error in
            guard error == nil else { completion?(nil, error); return }
            guard let stringURL = response?["url"] as? String, let url = URL(string: stringURL) else {
                let noURLError = NSError(domain: "Response doesn't contain URL", code: 1)
                completion?(nil, noURLError)
                return
            }
            completion?(url, error)
        }
    }

    public func requestOnlineStatusFor(contact: Contact) {
        guard let userID = contact.userID else { return }
        ServerFacade.sharedInstance().checkOnlineStatus(forUserID: userID)
    }
}
