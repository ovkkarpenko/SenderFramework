//
// Created by Roman Serga on 27/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSendBarCreator)
public class SendBarCreator: NSObject, SendBarCreatorProtocol {

    @objc public func createSendBar() -> BarModel {
        guard let barModel = CoreDataFacade.sharedInstance().getNewObject(withName: "BarModel") as? BarModel else {
            fatalError("Cannot get BarModel from CoreDataFacade")
        }
        return barModel
    }

    @objc public func deleteSendBar(_ sendBar: BarModel) {
        CoreDataFacade.sharedInstance().delete(sendBar)
    }
}
