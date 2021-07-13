//
// Created by Roman Serga on 23/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatListDataManager: ChatListDataManagerProtocol {
    weak var isSyncingChangesObserver: SenderCoreInSyncingObserver?
    private var isObservingNotifications = false

    func startObservingIsSyncingChangesWith(observer: SenderCoreInSyncingObserver) {
        self.isSyncingChangesObserver = observer
        if !isObservingNotifications {
            self.isObservingNotifications = true
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.synchronizationStarted),
                                                   name: Notification.Name(rawValue: SenderCoreWillStartSynchronization),
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.synchronizationFinished),
                                                   name: Notification.Name(rawValue: SenderCoreDidFailSynchronization),
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.synchronizationFinished),
                                                   name: Notification.Name(rawValue: SenderCoreDidFinishSynchronization),
                                                   object: nil)
        }
    }

    func stopObservingIsSyncingChanges() {
        self.isSyncingChangesObserver = nil
        self.isObservingNotifications = false
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name(rawValue: SenderCoreWillStartSynchronization),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name(rawValue: SenderCoreDidFailSynchronization),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name(rawValue: SenderCoreDidFinishSynchronization),
                                                  object: nil)
    }

    @objc func synchronizationStarted() {
        self.isSyncingChangesObserver?.senderCore(SenderCore.shared(), isSyncingDidChange: true)
    }

    @objc func synchronizationFinished() {
        self.isSyncingChangesObserver?.senderCore(SenderCore.shared(), isSyncingDidChange: false)
    }
}
