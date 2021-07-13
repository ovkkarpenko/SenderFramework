//
// Created by Roman Serga on 23/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatListInteractor: ChatListInteractorProtocol, SenderCoreInSyncingObserver {
    var dataManager: ChatListDataManagerProtocol
    weak var presenter: ChatListPresenterProtocol?

    init(dataManager: ChatListDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        let isSyncing = SenderCore.shared().isSynchronizationIsProgress
        self.presenter?.handleIsSyncingState(isSyncing)
        self.dataManager.startObservingIsSyncingChangesWith(observer: self)
    }

    func senderCore(_ senderCore: SenderCore, isSyncingDidChange isSyncing: Bool) {
        self.presenter?.handleIsSyncingState(isSyncing)
    }
}
