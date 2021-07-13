//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SettingsDataManager: SettingsDataManagerProtocol {

    func saveSettings(_ settings: Settings,
                      completionHandler: ((Bool, Error?) -> Void)?) {
        completionHandler?(true, nil)
    }

    func getBlockedChats(completion: (([Dialog], Error?) -> Void)?) {
        let blockedChats = (CoreDataFacade.sharedInstance().getBlockedChats() as? [Dialog]) ?? []
        completion?(blockedChats, nil)
    }
}
