//
// Created by Roman Serga on 27/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarItemCreator)
public class SendBarItemCreator: NSObject, SendBarItemCreatorProtocol {

    @objc public func createSendBarItem() -> BarItem {
        guard let barItem = CoreDataFacade.sharedInstance().getNewObject(withName: "BarItem") as? BarItem else {
            fatalError("Cannot get BarItem from CoreDataFacade")
        }
        return barItem
    }

    @objc public func deleteSendBarItem(_ sendBarItem: BarItem) {
        CoreDataFacade.sharedInstance().delete(sendBarItem)
    }
}
