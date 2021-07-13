//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BlockedUsersDataManager: BlockedUsersDataManagerProtocol {

    var chatEditManager: ChatEditManager

    init(chatEditManager: ChatEditManager) {
        self.chatEditManager = chatEditManager
    }

    func loadBlockedChats(completion: (([Dialog]) -> Void)?) {
        let blockedChats = (CoreDataFacade.sharedInstance().getBlockedChats() as? [Dialog]) ?? [Dialog]()
        completion?(blockedChats)
    }

    func unblockChat(_ chat: Dialog, completion: ((Dialog?, Error?) -> Void)?) {
        let chatSettings = chat.dialogSetting()
        let settingsEditModel = ChatSettingsEditModel(chatSettings: chatSettings)
        settingsEditModel.isBlocked = false
        self.chatEditManager.changeSettingsOf(chat: chat,
                                              newSettings: settingsEditModel,
                                              completionHandler: completion)
    }

}
