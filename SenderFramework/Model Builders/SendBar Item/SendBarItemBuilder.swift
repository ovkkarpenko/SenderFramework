//
// Created by Roman Serga on 26/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarItemBuilder)
public class SendBarItemBuilder: NSObject, SendBarItemBuilderProtocol {

    public func validateDictionary(_ dictionary: [String: Any]) throws {
        if dictionary["id"] as? String == nil  {
            let error = NSError(domain: "Cannot create SendBar item without ID", code: 666)
            throw error
        }
    }

    @objc public func setDataFrom(dictionary: [String: Any], to sendBarItem: BarItem) throws -> BarItem {
        do {
            try self.validateDictionary(dictionary)
        } catch let error as NSError {
            throw error
        } catch {
            throw NSError(domain: "Cannot create SendBar item", code: 666)
        }

        sendBarItem.itemID =  dictionary["id"]! as! String

        let nameDictionary = dictionary["name"] as? [AnyHashable: Any]
        sendBarItem.name = ParamsFacade.sharedInstance().nsData(from: nameDictionary)

        sendBarItem.icon = dictionary["icon"] as? String
        sendBarItem.icon2 = dictionary["icon2"] as? String

        let actionsArray = dictionary["actions"] as? [Any]
        sendBarItem.actions = ParamsFacade.sharedInstance().nSdate(from: actionsArray)

        return sendBarItem
    }

    @objc public func update(sendBarItem: BarItem, with dictionary: [String: Any]) throws -> BarItem {
        return sendBarItem
    }

}
