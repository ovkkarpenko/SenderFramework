//
// Created by Roman Serga on 27/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatSettingsCreator)
public class ChatSettingsCreator: NSObject, ChatSettingsCreatorProtocol {

    @objc public func createChatSettings() -> DialogSetting {
        let dataFacade = CoreDataFacade.sharedInstance()
        guard let chatSettings = dataFacade.getNewObject(withName: "DialogSetting") as? DialogSetting else {
            fatalError("Cannot get DialogSetting from CoreDataFacade")
        }
        return chatSettings
    }

    @objc public func deleteChatSettings(_ chatSettings: DialogSetting) {
        CoreDataFacade.sharedInstance().delete(chatSettings)
    }

}
