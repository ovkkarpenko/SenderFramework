//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol CallRobotInteractorProtocol: ChatInteractorProtocol {
    var callRobotModel: CallRobotModelProtocol! { get set }
}

@objc public protocol CallRobotModuleProtocol: ChatModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     callRobotModel: CallRobotModelProtocol,
                     forDelegate delegate: ChatModuleDelegate?,
                     completion: (() -> Void)?)
}

@objc public protocol CallRobotModelProtocol {
    var robotID: String? { get }
    var companyID: String? { get }
    var formID: String? { get set }
    var chatID: String? { get set }
    var userID: String? { get set }
    var model: [AnyHashable: Any]? { get set }
}
