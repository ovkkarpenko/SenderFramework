//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public protocol ChatSettingsViewProtocol: class {
    func updateWith(viewModel: ChatSettingsChatViewModel)
}

@objc public protocol ChatSettingsModuleDelegate: class {
    func chatSettingsModuleDidUpdateChat(_ chat: Dialog)
    func chatSettingsModule(_ chatSettingsModule: ChatSettingsModuleProtocol,
                            shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool
    func chatSettingsModule(_ chatSettingsModule: ChatSettingsModuleProtocol,
                            shouldOpenChat chat: Dialog,
                            withActions actions: [[String: AnyObject]]?) -> Bool
    func chatSettingsModuleDidFinish(_ chatSettingsModule: ChatSettingsModuleProtocol)
}

public protocol ChatSettingsPresenterDelegate: class {
    func chatSettingsPresenterDidUpdateChat(_ chat: Dialog)
    func chatSettingsPresenter(_ chatSettingsPresenter: ChatSettingsPresenterProtocol,
                               shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool
    func chatSettingsPresenter(_ chatSettingsPresenter: ChatSettingsPresenterProtocol,
                               shouldOpenChat chat: Dialog,
                               withActions actions: [[String: AnyObject]]?) -> Bool
    func chatSettingsModuleDidFinish(_ chatSettingsPresenter: ChatSettingsPresenterProtocol)
}

public protocol ChatSettingsPresenterProtocol: class, AddToChatModuleDelegate {
    weak var delegate: ChatSettingsPresenterDelegate? { get set }

    func viewWasLoaded()

    func chatWasUpdated(_ chat: Dialog)

    func addParticipants()
    func callRobotWith(info: [AnyHashable: Any])
    func callRobotWith(robotModel: CallRobotModel)
    func goToChatWith(actions: [[String: AnyObject]]?)
    func callPhone(_ phone: ChatSettingsPhoneViewModel)
    func copyPhone(_ phone: ChatSettingsPhoneViewModel)

    func changeEncryptionStateTo(_ newEncryptionState: Bool)
    func changeFavoriteStateTo(_ newFavoriteState: Bool)
    func changeBlockStateTo(_ newBlockState: Bool)

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme)
    func changeChatNotificationOption(_ notificationOption: SelectableChatSetting<ChatSettingsNotificationType, String>,
                                      to newValue: ChatSettingsNotificationType)

    func closeChatSettings()
}

public protocol ChatSettingsRouterProtocol: class {
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatSettingsPresenterDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func presentAddMemberScreenWith(chat: Dialog)
    func dismissAddMemberScreen()

    func presentChatScreenWith(chat: Dialog, actions: [[String: AnyObject]]?)
    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol)
}

public protocol ChatSettingsInteractorProtocol: class, ChatsChangesHandler {
    var chat: Dialog! { get }

    func updateWith(chat: Dialog)

    func loadData()

    func addMembers(_ members: [Dialog])
    func callPhone(_ phone: Item)
    func copyPhone(_ phone: Item)

    func changeEncryptionStateTo(_ newEncryptionState: Bool)
    func changeFavoriteStateTo(_ newFavoriteState: Bool)
    func changeBlockStateTo(_ newBlockState: Bool)

    func changeSoundSchemeTo(_ newSoundScheme: ChatSettingsSoundScheme)
    func changeMuteChatStateTo(_ newMuteState: ChatSettingsNotificationType)
    func changeHidePushStateTo(_ newHidePushState: ChatSettingsNotificationType)
    func changeSmartPushStateTo(_ newSmartPushState: ChatSettingsNotificationType)
    func changeHideTextStateTo(_ newHideTextState: ChatSettingsNotificationType)
    func changeHideCounterStateTo(_ newHideCounterState: ChatSettingsNotificationType)
}

public protocol ChatSettingsDataManagerProtocol {
    func add(members: [Dialog],
             toChat chat: Dialog,
             completionHandler: ((Dialog?, Error?) -> Void)?)

    func setEncryptionStateOf(chat: Dialog,
                              encryptionState: Bool,
                              completionHandler: ((Dialog?, Error?) -> Void)?)

    func changeSettingsOf(chat: Dialog,
                          newSettings: ChatSettingsEditModel,
                          completionHandler: ((Dialog?, Error?) -> Void)?)

    func startChatChangesObservingWith(chatChangesHandler: ChatsChangesHandler)
    func stopChatChangesObserving()
}

@objc public protocol ChatSettingsModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     chat: Dialog,
                     forDelegate delegate: ChatSettingsModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}
