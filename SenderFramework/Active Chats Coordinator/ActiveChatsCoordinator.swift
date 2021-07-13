//
// Created by Roman Serga on 7/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChat)
public protocol Chat: class {
    var isActive: Bool { get }
    var chatID: String! { get }
}

@objc(ActiveChatsCoordinator)
public class ActiveChatsCoordinator: NSObject {
    fileprivate let chats = NSHashTable<AnyObject>(options: NSHashTableWeakMemory, capacity: 10)

    @objc public var allActiveChatIDs: [String] {
        return synchronized(self) {
            return self.chats.allObjects.flatMap({
                return $0 as? Chat
            }).filter({
                return $0.isActive
            }).map({
                return $0.chatID
            })
        }
    }

    @objc public var activeChatID: String? {
        return allActiveChatIDs.last
    }

    @objc public func addChat(_ chat: Chat) {
        synchronized(self) {
            weak var weakChat = chat
            if weakChat != nil {
                self.chats.add(weakChat)
            }
        }
    }

    @objc public func removeChat(_ chat: Chat) {
        synchronized(self) {
            self.chats.remove(chat)
        }
    }
}
