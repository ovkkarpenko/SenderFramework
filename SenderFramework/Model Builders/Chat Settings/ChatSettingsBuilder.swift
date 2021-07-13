//
// Created by Roman Serga on 25/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatSettingsBuilder)
public class ChatSettingsBuilder: NSObject, ChatSettingsBuilderProtocol {

    @objc public func setDataFrom(dictionary: [String: Any], to chatSettings: DialogSetting) -> DialogSetting {

        chatSettings.blockChat = NSNumber(value: (dictionary["block"] as? Bool) ?? false)
        chatSettings.favChat = NSNumber(value: (dictionary["fav"] as? Bool) ?? false)
        chatSettings.chatSoundScheme = dictionary.transformedValueFor(key: "snd",
                                                                      transform: chatSettingsSoundSchemeFromString,
                                                                      defaultValue: .default)

        chatSettings.muteChatNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "m")
        chatSettings.hidePushNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "h")
        chatSettings.smartPushNotification = notificationTypeFrom(dictionary: dictionary,
                                                                  parentKey: "ntf",
                                                                  childKey: "s")
        chatSettings.hideTextNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "t")
        chatSettings.hideCounterNotification = notificationTypeFrom(dictionary: dictionary,
                                                                    parentKey: "ntf",
                                                                    childKey: "c")

        return chatSettings
    }

    @objc public func update(chatSettings: DialogSetting, with dictionary: [String: Any]) -> DialogSetting {

        if let blockChat = dictionary["block"] as? Bool { chatSettings.blockChat = NSNumber(value: blockChat) }
        if let favChat = dictionary["fav"] as? Bool { chatSettings.favChat = NSNumber(value: favChat) }
        chatSettings.chatSoundScheme = dictionary.transformedValueFor(key: "snd",
                                                                      transform: chatSettingsSoundSchemeFromString,
                                                                      defaultValue: chatSettings.chatSoundScheme)

        chatSettings.muteChatNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "m",
                                                                 defaultValue: chatSettings.muteChatNotification)
        chatSettings.hidePushNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "h",
                                                                 defaultValue: chatSettings.hidePushNotification)
        chatSettings.smartPushNotification = notificationTypeFrom(dictionary: dictionary,
                                                                  parentKey: "ntf",
                                                                  childKey: "s",
                                                                  defaultValue: chatSettings.smartPushNotification)
        chatSettings.hideTextNotification = notificationTypeFrom(dictionary: dictionary,
                                                                 parentKey: "ntf",
                                                                 childKey: "t",
                                                                 defaultValue: chatSettings.hideTextNotification)
        chatSettings.hideCounterNotification = notificationTypeFrom(dictionary: dictionary,
                                                                    parentKey: "ntf",
                                                                    childKey: "c",
                                                                    defaultValue: chatSettings.hideCounterNotification)

        return chatSettings
    }
}

extension Dictionary {

    func transformedValueFor<FromType, ToType>(key: Key,
                                               transform:((FromType) -> ToType),
                                               defaultValue: ToType) -> ToType {
        let result: ToType
        if let fromValue = self[key] as? FromType {
            result = transform(fromValue)
        } else {
            result = defaultValue
        }
        return result
    }

}

fileprivate func notificationTypeFrom(dictionary: [String: Any],
                                      parentKey: String,
                                      childKey: String,
                                      defaultValue: ChatSettingsNotificationType = .disabled) -> ChatSettingsNotificationType {

    func notificationTypeFromDictionaryFor(key: String) -> (([String: Any]) -> ChatSettingsNotificationType)
    {
        return { (dictionary: [String: Any]) in
            return dictionary.transformedValueFor(key: key,
                                                  transform: chatSettingsNotificationTypeFromString,
                                                  defaultValue: defaultValue)
        }
    }

    return dictionary.transformedValueFor(key: parentKey,
                                          transform: notificationTypeFromDictionaryFor(key: childKey),
                                          defaultValue: defaultValue)
}