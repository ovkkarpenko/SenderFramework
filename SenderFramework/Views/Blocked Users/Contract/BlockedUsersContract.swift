//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol BlockedUsersDataManagerProtocol {
    func loadBlockedChats(completion: (([Dialog]) -> Void)?)
    func unblockChat(_ chat: Dialog, completion: ((Dialog?, Error?) -> Void)?)
}

@objc public protocol BlockedUsersModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: EntityPickerModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}