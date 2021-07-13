//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class MessagesReadSender {
    var dataManager: ChatDataManagerProtocol
    var messageToChange: Message?
    var workItem: DispatchWorkItem?

    init(dataManager: ChatDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func reset() {
        self.workItem = nil
        self.messageToChange = nil
    }

    func sendReadFor(message: Message) {
        if let messageToChange = self.messageToChange, let messageToChangePacketID = messageToChange.packetID {
            if (message.packetID as NSString).compare(messageToChangePacketID,
                                                      options: .numeric) == .orderedDescending {
                self.workItem?.cancel()
                self.prepareMessageForSendingRead(message)
            }
        } else {
            self.prepareMessageForSendingRead(message)
        }
    }

    fileprivate func prepareMessageForSendingRead(_ message: Message) {
        self.messageToChange = message
        self.workItem = DispatchWorkItem {
            self.dataManager.sendReadFor(message: message)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.workItem!)
    }
}
