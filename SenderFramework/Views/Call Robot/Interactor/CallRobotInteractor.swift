//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CallRobotInteractor: ChatInteractor, CallRobotInteractorProtocol {
    var callRobotModel: CallRobotModelProtocol!

    override func loadData() {
        super.loadData()
        self.dataManager.callRobotWith(model: self.callRobotModel, completion: nil)
    }
}