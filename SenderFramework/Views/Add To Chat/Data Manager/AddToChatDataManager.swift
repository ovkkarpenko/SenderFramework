//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddToChatDataManager: AddToChatDataManagerProtocol {

    var chatEditManager: ChatEditManager

    init(chatEditManager: ChatEditManager) {
        self.chatEditManager = chatEditManager
    }

    func add(members: [Dialog],
             toChat chat: Dialog,
             completionHandler: ((Dialog?, Error?) -> Void)?) {
        self.chatEditManager.add(members: members, toChat: chat, completionHandler: completionHandler)
    }

    func loadEntities(completion: (([Dialog]) -> Void)?) {
        let chats = (CoreDataFacade.sharedInstance().getP2PChats() as? [Dialog]) ?? [Dialog]()
        completion?(chats)
    }

}
