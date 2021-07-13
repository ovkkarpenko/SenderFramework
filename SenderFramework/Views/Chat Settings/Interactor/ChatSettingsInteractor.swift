//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import libPhoneNumber_iOS

class ChatSettingsInteractor: ChatSettingsInteractorProtocol {
    var chat: Dialog!
    weak var _presenter: ChatSettingsPresenterProtocol?
    var _dataManager: ChatSettingsDataManagerProtocol

    init(dataManager: ChatSettingsDataManagerProtocol) {
        self._dataManager = dataManager
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(self)
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
        self._presenter?.chatWasUpdated(self.chat)
    }

    func loadData() {
        self._dataManager.startChatChangesObservingWith(chatChangesHandler: self)
        self._presenter?.chatWasUpdated(self.chat)
    }

    func addMembers(_ members: [Dialog]) {
        self._dataManager.add(members: members,
                              toChat: self.chat,
                              completionHandler: self.refreshPresenterWith)
    }

    func refreshPresenterWith(chat: Dialog?, error: Error?) {
        guard let newChat = chat, error == nil else { return }
        self.updateWith(chat: newChat)
    }

    func changeEncryptionStateTo(_ newEncryptionState: Bool) {
        self._dataManager.setEncryptionStateOf(chat: self.chat,
                                               encryptionState: newEncryptionState,
                                               completionHandler: self.refreshPresenterWith)
    }

    func changeFavoriteStateTo(_ newFavoriteState: Bool) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.isFavorite = newFavoriteState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeBlockStateTo(_ newBlockState: Bool) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.isBlocked = newBlockState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.soundScheme = newSoundScheme
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.muteChatNotification = newMuteState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hidePushNotification = newHidePushState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.smartPushNotification = newSmartPushState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hideTextNotification = newHideTextState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType) {
        let editSettings = ChatSettingsEditModel(chatSettings: self.chat.dialogSetting())
        editSettings.hideCounterNotification = newHideCounterState
        self.updateChat(self.chat, withSettings: editSettings)
    }

    private func updateChat(_ chat: Dialog, withSettings settings: ChatSettingsEditModel) {
        self._dataManager.changeSettingsOf(chat: chat,
                                           newSettings: settings,
                                           completionHandler: self.refreshPresenterWith)
    }

    func callPhone(_ phone: Item) {
        guard let phoneNumber = phone.value, !phoneNumber.isEmpty else { return }
        self.callPhoneNumber(phoneNumber)
    }

    func callPhoneNumber(_ phoneNumber: String) {
        var formattedPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
        if !formattedPhone.hasPrefix("+") { formattedPhone = "+" + formattedPhone }
        let phoneURLString = "telprompt://" + formattedPhone
        guard let phoneUrl = URL(string: phoneURLString) else { return }
        SenderCore.shared().application.openURL(phoneUrl)
    }

    func handleChatsChange(_ chats: [Dialog]) {
        for chat in chats where chat.chatID == self.chat.chatID {
            self.updateWith(chat: chat)
        }
    }

    func copyPhone(_ phone: Item) {
        let pasteBoard = UIKit.UIPasteboard.general
        guard let phoneRaw = phone.value else { return }
        let phone = phoneRaw.hasPrefix("+") ? phoneRaw : "+" + phoneRaw
        let phoneNumberUtil = NBPhoneNumberUtil()
        if let parsedNumber = try? phoneNumberUtil.parse(phone, defaultRegion: "UA"),
           let formattedPhone = try? phoneNumberUtil.format(parsedNumber, numberFormat: .INTERNATIONAL) {
            pasteBoard.string = formattedPhone
        } else {
            pasteBoard.string = phone
        }
    }
}
