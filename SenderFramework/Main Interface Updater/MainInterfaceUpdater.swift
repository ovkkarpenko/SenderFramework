//
//  MainInterfaceUpdater.swift
//  SENDER
//
//  Created by Roman Serga on 2/6/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

@objc public protocol UpdatesHandler: class {}

@objc public protocol MessagesChangesHandler: UpdatesHandler {
    func handleMessagesUpdate(_ updatedMessages: [Message])
    func handleMessagesAdding(_ newMessages: [Message])
    func handleMessagesRemoval(_ removedMessages: [Message])
}

@objc public protocol ChatsChangesHandler: UpdatesHandler {
    func handleChatsChange(_ chats: [Dialog])
}

@objc public protocol OnlineStatusChangesHandler: UpdatesHandler {
    func handleOnlineStatusChangeForContacts(_ contacts: [Contact])
}

@objc public protocol TypingChangesHandler: UpdatesHandler {
    func handleTypingStartForContacts(_ contacts: [Contact], inChat chatID: String)
}

@objc public protocol UnreadMessagesCountChangesHandler: UpdatesHandler {
    func handleUnreadMessagesCountChange(_ newUnreadMessagesCount: Int)
}

@objc public protocol MessagesGapsChangesHandler: UpdatesHandler {
    func handleGapsAdding(_ newMessagesGaps: [MessagesGap])
    func handleGapsRemoval(_ removedMessagesGaps: [MessagesGap])
}

@objc public protocol OwnerChangesHandler: UpdatesHandler {
    func handleOwnerChange(_ owner: Owner)
}

@objc open class MainInterfaceUpdater: NSObject {

    fileprivate let updateHandlers = NSHashTable<AnyObject>(options: NSHashTableWeakMemory, capacity: 10)

    @objc open func addUpdatesHandler(_ handler: UpdatesHandler) {
        synchronized(self) {
            weak var weakHandler = handler
            if weakHandler != nil {
                self.updateHandlers.add(weakHandler!)
            }
        }
    }

    @objc open func removeUpdatesHandler(_ handler: UpdatesHandler) {
        synchronized(self) {
            self.updateHandlers.remove(handler)
        }
    }

    @objc open func messagesWereUpdated(_ messages: [Message]) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is MessagesChangesHandler
            }.map {
                ($0 as? MessagesChangesHandler)?.handleMessagesUpdate(messages)
            }
        }
    }

    @objc open func messagesWereAdded(_ messages: [Message]) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is MessagesChangesHandler
            }.map {
                ($0 as? MessagesChangesHandler)?.handleMessagesAdding(messages)
            }
        }
    }

    @objc open func messagesWereRemoved(_ messages: [Message]) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is MessagesChangesHandler
            }.map {
                ($0 as? MessagesChangesHandler)?.handleMessagesRemoval(messages)
            }
        }
    }

    @objc open func chatsWereChanged(_ chats: [Dialog]) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is ChatsChangesHandler
            }.map {
                ($0 as? ChatsChangesHandler)?.handleChatsChange(chats)
            }
        }
    }

    @objc open func unreadMessagesCountWasChanged(_ newUnreadMessagesCount: Int) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is UnreadMessagesCountChangesHandler
            }.map {
                ($0 as? UnreadMessagesCountChangesHandler)?.handleUnreadMessagesCountChange(newUnreadMessagesCount)
            }
        }
    }

    @objc open func onlineStatusWasChangedForContacts(_ contacts: [Contact]) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is OnlineStatusChangesHandler
            }.map {
                ($0 as? OnlineStatusChangesHandler)?.handleOnlineStatusChangeForContacts(contacts)
            }
        }
    }

    @objc open func contactsStartedTyping(_ contacts: [Contact], inChat chatID: String) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is TypingChangesHandler
            }.map {
                ($0 as? TypingChangesHandler)?.handleTypingStartForContacts(contacts, inChat: chatID)
            }
        }
    }

    @objc open func ownerWasChanged(_ owner: Owner) {
        synchronized(self) {
            _ = self.updateHandlers.allObjects.filter {
                $0 is OwnerChangesHandler
            }.map {
                ($0 as? OwnerChangesHandler)?.handleOwnerChange(owner)
            }
        }
    }

    @objc open func messagesGapsWereAdded(_ messagesGaps: [MessagesGap]) {
        synchronized(self) {
            self.updateHandlers.allObjects.forEach { updatesHandler in
                (updatesHandler as? MessagesGapsChangesHandler)?.handleGapsAdding(messagesGaps)
            }
        }
    }

    @objc open func messagesGapsWereRemoved(_ messagesGaps: [MessagesGap]) {
        synchronized(self) {
            self.updateHandlers.allObjects.forEach { updatesHandler in
                (updatesHandler as? MessagesGapsChangesHandler)?.handleGapsRemoval(messagesGaps)
            }
        }
    }}
