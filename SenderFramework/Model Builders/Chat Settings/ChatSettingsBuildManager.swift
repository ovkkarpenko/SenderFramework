//
// Created by Roman Serga on 10/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatSettingsCreatorProtocol)
public protocol ChatSettingsCreatorProtocol {
    func createChatSettings() -> DialogSetting
    func deleteChatSettings(_ chatSettings: DialogSetting)
}

@objc(MWChatSettingsBuilderProtocol)
public protocol ChatSettingsBuilderProtocol {

    func setDataFrom(dictionary: [String: Any], to chatSettings: DialogSetting) -> DialogSetting
    func update(chatSettings: DialogSetting, with dictionary: [String: Any]) -> DialogSetting
}

@objc(MWChatSettingsBuildManagerProtocol)
public protocol ChatSettingsBuildManagerProtocol {

    var chatSettingsCreator: ChatSettingsCreatorProtocol { get }
    var chatSettingsBuilder: ChatSettingsBuilderProtocol { get }

    init(chatSettingsCreator: ChatSettingsCreatorProtocol, chatSettingsBuilder: ChatSettingsBuilderProtocol)

    func chatSettingsWith(dictionary: [String: Any]) -> DialogSetting
    func setDataFrom(dictionary: [String: Any], to chatSettings: DialogSetting) -> DialogSetting
    func update(chatSettings: DialogSetting, with dictionary: [String: Any]) -> DialogSetting

    func deleteChatSettings(_ chatSettings: DialogSetting)
}

@objc(MWChatSettingsBuildManager)
public class ChatSettingsBuildManager: NSObject, ChatSettingsBuildManagerProtocol {

    @objc public var chatSettingsCreator: ChatSettingsCreatorProtocol
    @objc public var chatSettingsBuilder: ChatSettingsBuilderProtocol

    @objc required public init(chatSettingsCreator: ChatSettingsCreatorProtocol,
                               chatSettingsBuilder: ChatSettingsBuilderProtocol) {
        self.chatSettingsCreator = chatSettingsCreator
        self.chatSettingsBuilder = chatSettingsBuilder
        super.init()
    }

    @objc public func chatSettingsWith(dictionary: [String: Any]) -> DialogSetting {
        let chatSettings = self.chatSettingsCreator.createChatSettings()
        return self.chatSettingsBuilder.setDataFrom(dictionary: dictionary, to: chatSettings)
    }

    @objc public func setDataFrom(dictionary: [String: Any], to chatSettings: DialogSetting) -> DialogSetting {
        return self.chatSettingsBuilder.setDataFrom(dictionary: dictionary, to: chatSettings)
    }

    @objc public func update(chatSettings: DialogSetting, with dictionary: [String: Any]) -> DialogSetting {
        return self.chatSettingsBuilder.update(chatSettings: chatSettings, with: dictionary)
    }

    @objc public func deleteChatSettings(_ chatSettings: DialogSetting) {
        self.chatSettingsCreator.deleteChatSettings(chatSettings)
    }
}
