//
// Created by Roman Serga on 27/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatCreator)
public class ChatCreator: NSObject, ChatCreatorProtocol {

    @objc public func createChat() -> Dialog {
        guard let chat = CoreDataFacade.sharedInstance().getNewObject(withName: "Dialog") as? Dialog else {
            fatalError("Cannot get Dialog from CoreDataFacade")
        }
        CoreDataFacade.sharedInstance().getOwner().addDialogsObject(chat)
        return chat
    }

    @objc public func chatWith(id: String) -> Dialog? {
        return CoreDataFacade.sharedInstance().dialog(withChatIDIfExist: id)
    }

    @objc public func deleteChat(_ chat: Dialog) {
        CoreDataFacade.sharedInstance().delete(chat)
        CoreDataFacade.sharedInstance().getOwner().removeDialogsObject(chat)
    }
}
