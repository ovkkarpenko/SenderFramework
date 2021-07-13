//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsDataManager: ChatEditManager, ChatSettingsDataManagerProtocol {
    private weak var chatChangesHandler: ChatsChangesHandler?

    func startChatChangesObservingWith(chatChangesHandler: ChatsChangesHandler) {
        if let oldChatChangesHandler = self.chatChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(oldChatChangesHandler)
        }
        self.chatChangesHandler = chatChangesHandler
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(chatChangesHandler)
    }

    func stopChatChangesObserving() {
        if let chatChangesHandler = self.chatChangesHandler {
            SenderCore.shared().interfaceUpdater.removeUpdatesHandler(chatChangesHandler)
        }
        self.chatChangesHandler = nil
    }
}
