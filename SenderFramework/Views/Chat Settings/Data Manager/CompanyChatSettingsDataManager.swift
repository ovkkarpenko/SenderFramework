//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsDataManager: ChatSettingsDataManager, CompanyChatSettingsDataManagerProtocol {
    private weak var messagesChangesHandler: MessagesChangesHandler?

    func complainAbout(user: Contact, withText text: String, completion: ((Bool) -> Void)?) {
        guard let userID = user.userID else { completion?(false); return }
        ServerFacade.sharedInstance().sendComplaintAboutUser(withID: userID, withReason: text) { response, error in
            completion?(response != nil && error == nil)
        }
    }

    func loadCompanyCardFor(chat: Dialog, completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().loadCompanyCard(forP2PChat: chat) { response, error in
            let isSuccess = response != nil && error == nil
            completion?(isSuccess, error)
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
}
