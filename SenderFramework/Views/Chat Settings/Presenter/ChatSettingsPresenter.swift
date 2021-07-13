//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsPresenter: ChatSettingsPresenterProtocol {
    weak var _view: ChatSettingsViewProtocol?
    weak var delegate: ChatSettingsPresenterDelegate?
    var _router: ChatSettingsRouterProtocol?
    var _interactor: ChatSettingsInteractorProtocol
    var chatSettingsModule: ChatSettingsModuleProtocol?

    init(interactor: ChatSettingsInteractorProtocol, router: ChatSettingsRouterProtocol? = nil) {
        self._interactor = interactor
        self._router = router
    }

    func viewWasLoaded() {
        self._interactor.loadData()
    }

    func buildChatViewModelWith(chat: Dialog) -> ChatSettingsChatViewModel {
        let possibleNotificationSettings: [ChatSettingsNotificationType] = [.disabled, .enabled, .enabledLocally]

        func descriptionFor(chatNotificationType: ChatSettingsNotificationType) -> String {
            switch chatNotificationType {
            case .enabled: return SenderFrameworkLocalizedString("chat_settings_all_devices")
            case .disabled: return SenderFrameworkLocalizedString("chat_settings_disabled")
            case .enabledLocally: return SenderFrameworkLocalizedString("chat_settings_this_device")
            }
        }

        let notificationSettingsWithDescriptions = possibleNotificationSettings.map({
            ($0, descriptionFor(chatNotificationType: $0))
        })

        let chatSettings = chat.dialogSetting()

        let muteChatNotification = (chatSettings.muteChatNotification,
                ChatSettingsViewModel.muteChatNotificationIdentifier,
                SenderFrameworkLocalizedString("chat_settings_sound"))

        let hidePushNotification = (chatSettings.hidePushNotification,
                ChatSettingsViewModel.hidePushNotificationIdentifier,
                SenderFrameworkLocalizedString("chat_settings_notifications"))

        let hideTextNotification = (chatSettings.hideTextNotification,
                ChatSettingsViewModel.hideTextNotificationIdentifier,
                SenderFrameworkLocalizedString("chat_settings_hide_text"))

        let hideCounterNotification = (chatSettings.hideCounterNotification,
                ChatSettingsViewModel.hideCounterNotificationIdentifier,
                SenderFrameworkLocalizedString("chat_settings_counter"))

        func chatSettingWith(value: ChatSettingsNotificationType, identifier: String, description: String)
                        -> SelectableChatSetting<ChatSettingsNotificationType, String> {
            return SelectableChatSetting(options: notificationSettingsWithDescriptions,
                                         selectedIndex: possibleNotificationSettings.index(of: value) ?? 0,
                                         identifier: identifier,
                                         description: description)
        }

        let notificationsOptions = [muteChatNotification,
                                    hidePushNotification,
                                    hideTextNotification,
                                    hideCounterNotification].map(chatSettingWith)
        let chatSettingsViewModel = ChatSettingsViewModel(notificationsOptions: notificationsOptions,
                                                          chatSettings: chatSettings)
        return ChatSettingsChatViewModel(chat: chat, chatSettings: chatSettingsViewModel)
    }

    func chatWasUpdated(_ chat: Dialog) {
        let chatViewModel = self.buildChatViewModelWith(chat: chat)
        self._view?.updateWith(viewModel: chatViewModel)
    }

    func addParticipants() {
        self._router?.presentAddMemberScreenWith(chat: self._interactor.chat)
    }

    func changeEncryptionStateTo(_ newEncryptionState: Bool) {
        self._interactor.changeEncryptionStateTo(newEncryptionState)
    }

    func changeFavoriteStateTo(_ newFavoriteState: Bool) {
        self._interactor.changeFavoriteStateTo(newFavoriteState)
    }

    func changeBlockStateTo(_ newBlockState: Bool) {
        self._interactor.changeBlockStateTo(newBlockState)
    }

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme) {
        self._interactor.changeSoundSchemeTo(newSoundScheme)
    }

    func changeChatNotificationOption(_ notificationOption: SelectableChatSetting<ChatSettingsNotificationType, String>,
                                      to newValue: ChatSettingsNotificationType) {
        switch notificationOption.identifier {
        case ChatSettingsViewModel.muteChatNotificationIdentifier: self.changeMuteChatStateTo(newValue)
        case ChatSettingsViewModel.hidePushNotificationIdentifier: self.changeHidePushStateTo(newValue)
        case ChatSettingsViewModel.hideTextNotificationIdentifier: self.changeHideTextStateTo(newValue)
        case ChatSettingsViewModel.hideCounterNotificationIdentifier: self.changeHideCounterStateTo(newValue)
        default: break
        }
    }

    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType) {
        self._interactor.changeMuteChatStateTo(newMuteState)
    }

    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType) {
        self._interactor.changeHidePushStateTo(newHidePushState)
    }

    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType) {
        self._interactor.changeSmartPushStateTo(newSmartPushState)
    }

    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType) {
        self._interactor.changeHideTextStateTo(newHideTextState)
    }

    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType) {
        self._interactor.changeHideCounterStateTo(newHideCounterState)
    }

    func entityPickerModuleDidCancel() {
        self._router?.dismissAddMemberScreen()
    }

    func addToChatModuleDidFinishWith(newChat: Dialog, selectedEntities: [EntityViewModel]) {
        self._router?.dismissAddMemberScreen()
        self._interactor.updateWith(chat: newChat)
        self.delegate?.chatSettingsPresenterDidUpdateChat(newChat)
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        self._router?.dismissAddMemberScreen()
    }

    func callRobotWith(info: [AnyHashable: Any]) {
        guard let callRobotModel = CallRobotModel(actionDictionary: info) else { return }
        self.callRobotWith(robotModel: callRobotModel)
    }

    func callRobotWith(robotModel: CallRobotModel) {
        let shouldCallRobot = self.delegate?.chatSettingsPresenter(self,
                                                                   shouldCallRobotWithModel: robotModel) ?? true
        guard shouldCallRobot else { return }
        self._router?.presentRobotScreenWith(callRobotModel: robotModel)
    }

    func goToChatWith(actions: [[String: AnyObject]]?) {
        guard let chatToOpen = self._interactor.chat else { return }
        let shouldOpenChat = self.delegate?.chatSettingsPresenter(self,
                                                                  shouldOpenChat: chatToOpen,
                                                                  withActions: actions) ?? true
        guard shouldOpenChat else { return }
        self._router?.presentChatScreenWith(chat: chatToOpen, actions: actions)
    }

    func closeChatSettings() {
        self.delegate?.chatSettingsModuleDidFinish(self)
    }

    func callPhone(_ phone: ChatSettingsPhoneViewModel) {
        self._interactor.callPhone(phone.item)
    }

    func copyPhone(_ phone: ChatSettingsPhoneViewModel) {
        self._interactor.copyPhone(phone.item)
    }
}
