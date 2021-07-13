//
// Created by Roman Serga on 22/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol SenderUIProtocol {
    func showMainScreenAnimated(_ animated: Bool) -> MainScreenModuleProtocol

    func showChatScreenWith(chat: Dialog,
                            actions: [[String: AnyObject]]?,
                            options: [String: Any]?,
                            animated: Bool,
                            modally: Bool,
                            delegate: ChatModuleDelegate?) -> ChatModuleProtocol?

    func showChatScreenWith(chatID: String,
                            actions: [[String: AnyObject]]?,
                            options: [String: Any]?,
                            animated: Bool,
                            modally: Bool,
                            delegate: ChatModuleDelegate?) -> ChatModuleProtocol

    func showChatWith(remoteNotification: [AnyHashable: Any],
                      animated: Bool,
                      modally: Bool,
                      delegate: ChatModuleDelegate?) -> ChatModuleProtocol?

    func showRobotScreenWith(model: CallRobotModelProtocol,
                             animated: Bool,
                             modally: Bool,
                             delegate: ChatModuleDelegate?) -> CallRobotModuleProtocol?

    func showChatList(animated: Bool,
                      modally: Bool,
                      forDelegate delegate: ChatListModuleDelegate?) -> ChatListModuleProtocol

    func showUserProfile(animated: Bool,
                         modally: Bool,
                         forDelegate delegate: UserProfileModuleDelegate?) -> UserProfileModuleProtocol

    func showSettings(animated: Bool,
                      modally: Bool,
                      forDelegate delegate: SettingsModuleDelegate?) -> SettingsModuleProtocol

    func showContactPageFor(chat: Dialog,
                            animated: Bool,
                            modally: Bool,
                            forDelegate delegate: ChatSettingsModuleDelegate?) -> ChatSettingsModuleProtocol

    func showCompanyPageFor(chat: Dialog,
                            animated: Bool,
                            modally: Bool,
                            forDelegate delegate: ChatSettingsModuleDelegate?) -> ChatSettingsModuleProtocol

    func showGroupChatPageFor(chat: Dialog,
                              animated: Bool,
                              modally: Bool,
                              forDelegate delegate: ChatSettingsModuleDelegate?) -> ChatSettingsModuleProtocol

    func showQRScreenWith(qrString: String,
                          delegate: QRScreenModuleDelegate?,
                          animated: Bool,
                          modally: Bool) -> QRScreenModuleProtocol?

    func showQRScannerWith(delegate: QRScannerModuleDelegate?,
                           animated: Bool,
                           modally: Bool) -> QRScannerModule?
}
