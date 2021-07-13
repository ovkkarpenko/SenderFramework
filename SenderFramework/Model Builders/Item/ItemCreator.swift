//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWItemCreator)
public class ItemCreator: NSObject, ItemCreatorProtocol {
    @objc public func createItem() -> Item {
        return CoreDataFacade.sharedInstance().getNewObject(withName:"Item") as! Item
    }

    @objc public func delete(item: Item) {
        CoreDataFacade.sharedInstance().delete(item)
    }
}
