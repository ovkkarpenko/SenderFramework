//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarItemCreatorProtocol)
public protocol SendBarItemCreatorProtocol {
    func createSendBarItem() -> BarItem
    func deleteSendBarItem(_ sendBarItem: BarItem)
}

@objc(MWSendBarItemBuilderProtocol)
public protocol SendBarItemBuilderProtocol: NSObjectProtocol {
    func setDataFrom(dictionary: [String: Any], to sendBarItem: BarItem) throws -> BarItem
    func update(sendBarItem: BarItem, with dictionary: [String: Any]) throws -> BarItem
    func validateDictionary(_ dictionary: [String: Any]) throws
}

@objc(MWSendBarItemBuildManagerProtocol)
public protocol SendBarItemBuildManagerProtocol {
    var sendBarItemCreator: SendBarItemCreatorProtocol { get }
    var sendBarItemBuilder: SendBarItemBuilderProtocol { get }

    init(sendBarItemCreator: SendBarItemCreatorProtocol, sendBarItemBuilder: SendBarItemBuilderProtocol)
    func barItemWith(dictionary: [String: Any]) throws -> BarItem
    func deleteSendBarItem(_ sendBarItem: BarItem)
}

@objc(MWSendBarItemBuildManager)
public class SendBarItemBuildManager: NSObject, SendBarItemBuildManagerProtocol {
    @objc public var sendBarItemCreator: SendBarItemCreatorProtocol
    @objc public var sendBarItemBuilder: SendBarItemBuilderProtocol

    @objc public required init(sendBarItemCreator: SendBarItemCreatorProtocol,
                               sendBarItemBuilder: SendBarItemBuilderProtocol) {
        self.sendBarItemBuilder = sendBarItemBuilder
        self.sendBarItemCreator = sendBarItemCreator
        super.init()
    }

    @objc public func barItemWith(dictionary: [String: Any]) throws -> BarItem {
        do {
            try self.sendBarItemBuilder.validateDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create SendBar item", code: 666)
        }

        let barItem = self.sendBarItemCreator.createSendBarItem()
        try self.sendBarItemBuilder.setDataFrom(dictionary: dictionary, to: barItem)
        return barItem
    }

    @objc public func deleteSendBarItem(_ sendBarItem: BarItem) {
        self.sendBarItemCreator.deleteSendBarItem(sendBarItem)
    }
}
