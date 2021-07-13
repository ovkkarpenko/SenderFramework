//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BlockedUsersInteractor: EntityPickerInteractor {

    var dataManager: BlockedUsersDataManagerProtocol

    init(dataManager: BlockedUsersDataManagerProtocol) {
        self.dataManager = dataManager
        super.init(allowsMultipleSelection: true)
    }

    override func loadData() {
        self.dataManager.loadBlockedChats { blockedChats in
            let entityModels = blockedChats.flatMap { ChatListChatViewModel(chat: $0) }
            self.updateWith(entities: entityModels)
        }
    }

    override func performAddingEntities(entities: [EntityViewModel]) {
        let chats = entities.flatMap { ($0 as? ChatListChatViewModel)?.chat }
        let dispatchGroup = DispatchGroup()
        for chat in chats {
            dispatchGroup.enter()
            self.dataManager.unblockChat(chat) { _, _ in
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.presenter?.finishPickingEntitiesWith(selectedEntities: entities)
        }
    }
}
