//
// Created by Roman Serga on 26/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarBuilder)
public class SendBarBuilder: NSObject, SendBarBuilderProtocol {

    @objc public var sendBarItemBuildManager: SendBarItemBuildManagerProtocol

    @objc public required init(sendBarItemBuildManager: SendBarItemBuildManagerProtocol) {
        self.sendBarItemBuildManager = sendBarItemBuildManager
        super.init()
    }

    @objc public func setDataFrom(dictionary: [String: Any], to sendBar: BarModel) -> BarModel {
        sendBar.mainTextColor = dictionary["textColor"] as? String

        let initData: Data?
        if let initDictionary = dictionary["init"] as? [AnyHashable: Any] {
            initData = ParamsFacade.sharedInstance().nsData(from: initDictionary)
        } else {
            initData = nil
        }

        sendBar.initializeData = initData

        if let itemsDictionary = dictionary["items"] as? [[String: Any]] {
            let barItems = itemsDictionary.flatMap {
                do {
                    return try self.sendBarItemBuildManager.barItemWith(dictionary: $0)
                } catch {
                    NSLog("Cannot create SendBar item with dictionary: \($0)")
                    return nil
                }
            } as [BarItem]
            sendBar.addBarItems(Set(barItems))
        } else {
            self.removeSendBarItemsOf(sendBar: sendBar)
        }

        return sendBar
    }

    @objc public func update(sendBar: BarModel, with dictionary: [String: Any]) -> BarModel {

        if let initDictionary = dictionary["init"] as? [AnyHashable: Any] {
            sendBar.initializeData = ParamsFacade.sharedInstance().nsData(from: initDictionary)
        }

        if let itemsDictionary = dictionary["items"] as? [[String: Any]] {
            self.removeSendBarItemsOf(sendBar: sendBar)
            let barItems = itemsDictionary.flatMap {
                do {
                    return try self.sendBarItemBuildManager.barItemWith(dictionary: $0)
                } catch {
                    NSLog("Cannot create SendBar item with dictionary: \($0)")
                    return nil
                }
            } as [BarItem]
            sendBar.addBarItems(Set(barItems))
        }

        return sendBar
    }

    private func removeSendBarItemsOf(sendBar: BarModel) {
        if let barItems = sendBar.barItems {
            sendBar.removeBarItems(barItems)
            for barItem in barItems { self.sendBarItemBuildManager.deleteSendBarItem(barItem) }
            _ = Array(barItems).map { self.sendBarItemBuildManager.deleteSendBarItem($0) }
        }
    }
}
