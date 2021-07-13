//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWItemBuilder)
public class ItemBuilder: NSObject, ItemBuilderProtocol {

    @objc public func setDataFrom(dictionary: [String: Any], to item: Item) throws -> Item {
        item.type = dictionary["type"] as? String
        let value = (dictionary["value"] as? String) ?? dictionary["valueRaw"] as? String
        item.value = value
        return item
    }

    @objc public func setPhone(phone: String, to item: Item) throws -> Item {
        item.value = phone
        item.type = "phone"
        return item
    }

    @objc public func update(item: Item, with dictionary: [String: Any]) throws -> Item {
        return item
    }
}
