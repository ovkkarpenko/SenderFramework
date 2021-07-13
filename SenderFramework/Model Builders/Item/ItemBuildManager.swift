//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWItemCreatorProtocol)
public protocol ItemCreatorProtocol {
    func createItem() -> Item
    func delete(item: Item)
}

@objc(MWItemBuilderProtocol)
public protocol ItemBuilderProtocol {
    func setDataFrom(dictionary: [String: Any], to item: Item) throws -> Item
    func setPhone(phone: String, to item: Item) throws -> Item
    func update(item: Item, with dictionary: [String: Any]) throws -> Item
}

@objc(MWItemBuildManagerProtocol)
public protocol ItemBuildManagerProtocol {

    var itemCreator: ItemCreatorProtocol { get }
    var itemBuilder: ItemBuilderProtocol { get }

    init(itemCreator: ItemCreatorProtocol, itemBuilder: ItemBuilderProtocol)

    func itemWith(phone: String) throws -> Item
    func itemWith(dictionary: [String: Any]) throws -> Item

    func deleteItem(_ item: Item)
}

@objc(MWItemBuildManager)
public class ItemBuildManager: NSObject, ItemBuildManagerProtocol {

    @objc public var itemCreator: ItemCreatorProtocol
    @objc public var itemBuilder: ItemBuilderProtocol

    @objc public required init(itemCreator: ItemCreatorProtocol, itemBuilder: ItemBuilderProtocol) {
        self.itemCreator = itemCreator
        self.itemBuilder = itemBuilder
        super.init()
    }

    @objc public func itemWith(dictionary: [String: Any]) throws -> Item {
        let item = self.itemCreator.createItem()
        try self.itemBuilder.setDataFrom(dictionary: dictionary, to: item)
        return item
    }

    @objc public func itemWith(phone: String) throws -> Item {
        let item = self.itemCreator.createItem()
        try self.itemBuilder.setPhone(phone: phone, to: item)
        return item
    }

    @objc public func deleteItem(_ item: Item) {
        self.itemCreator.delete(item: item)
    }
}
