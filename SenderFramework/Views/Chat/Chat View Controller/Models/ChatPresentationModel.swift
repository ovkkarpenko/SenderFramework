//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatPresentationModel: NSObject, ChatPresentationModelProtocol {
    public private(set) var chatID: String
    public private(set) var chat: Dialog?
    public var actions: [[String: Any]]?
    public var options: [String: Any]?

    public init(chatID: String) {
        self.chatID = chatID
    }

    public convenience init?(chat: Dialog) {
        guard let chatID = chat.chatID else { return nil }

        self.init(chatID: chatID)
        self.chat = chat
    }
}
