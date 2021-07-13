//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SettingsPresenter: SettingsPresenterProtocol {
    weak var view: SettingsViewProtocol?
    weak var delegate: SettingsModuleDelegate?
    var router: SettingsRouterProtocol?
    var interactor: SettingsInteractorProtocol

    init(interactor: SettingsInteractorProtocol, router: SettingsRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func settingsWereUpdated(_ settings: Settings) {
        self.view?.updateWith(viewModel: settings)
    }

    func blockedUsersCountWasUpdated(_ blockedUsersCount: Int) {
        self.view?.updateWith(blockedUsersCount: blockedUsersCount)
    }

    func changeSendReadStatusTo(_ newStatus: Bool) {
        self.interactor.changeSendReadStatusTo(newStatus)
    }

    func changeLocationMonitoringStatusTo(_ newStatus: Bool) {
        self.interactor.changeLocationMonitoringStatusTo(newStatus) { success, _ in
            if !success { self.view?.showLocationNotAvailableWarning() }
        }
    }

    func changeSoundStatusTo(_ newStatus: Bool) {
        self.interactor.changeSoundStatusTo(newStatus)
    }

    func changeNotificationSoundTo(_ newStatus: Bool) {
        self.interactor.changeNotificationSoundTo(newStatus)
    }

    func changeVibrationStatusTo(_ newStatus: Bool) {
        self.interactor.changeVibrationStatusTo(newStatus)
    }

    func changeFlashStatusTo(_ newStatus: Bool) {
        self.interactor.changeFlashStatusTo(newStatus)
    }

    func showBitcoinWallet() {
        self.router?.presentBitcoinWalletView()
    }

    func clearChatHistory() {
        self.interactor.clearChatHistory()
    }

    func disableDevice() {
        self.interactor.disableDevice()
    }

    func showActiveDevices() {
        self.router?.presentActiveDevicesView()
    }

    func showBlockedUsers() {
        self.router?.presentBlockedUsersView()
    }

    func entityPickerModuleDidCancel() {
        self.router?.dismissBlockedUsersView()
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        self.router?.dismissBlockedUsersView()
    }

    func closeSettings() {
        self.delegate?.settingsModuleDidFinish()
    }
}
