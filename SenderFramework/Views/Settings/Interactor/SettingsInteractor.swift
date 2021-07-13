//
// Created by Roman Serga on 12/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SettingsInteractor: SettingsInteractorProtocol {

    weak var presenter: SettingsPresenterProtocol?
    private(set) var settings: Settings!
    var dataManager: SettingsDataManagerProtocol
    var locationManager: SettingsLocationManagerProtocol
    var settingsEraser: SettingsEraserProtocol
    var blockedChats = [Dialog]()

    init(dataManager: SettingsDataManagerProtocol,
         locationManager: SettingsLocationManagerProtocol,
         settingsEraser: SettingsEraserProtocol) {
        self.dataManager = dataManager
        self.locationManager = locationManager
        self.settingsEraser = settingsEraser
    }

    func loadData() {
        self.presenter?.settingsWereUpdated(settings)
        self.dataManager.getBlockedChats { blockedChats, error in
            guard error == nil else { return }
            self.updateBlockedChats(newBlockedChats: blockedChats)
        }
    }

    func updateWith(settings: Settings) {
        self.settings = settings
        self.presenter?.settingsWereUpdated(settings)
    }

    func updateBlockedChats(newBlockedChats: [Dialog]) {
        self.blockedChats = newBlockedChats
        self.presenter?.blockedUsersCountWasUpdated(self.blockedChats.count)
    }

    fileprivate func setSettingsParameterValue<T>(value: T, getter: (() -> T), setter: @escaping ((T) -> Void)) {
        let oldValue = getter()
        setter(value)
        self.dataManager.saveSettings(self.settings) { success, error in
            if !success { setter(oldValue) }
            self.updateWith(settings: self.settings)
        }
    }

    func changeLocationMonitoringStatusTo(_ newStatus: Bool, completion: @escaping ((Bool, Error?) -> Void)) {
        guard self.settings.location.boolValue != newStatus else {
            completion(true, nil)
            return
        }

        let saveLocationValue: ((Bool) -> Void) = { locationValue in
            self.settings.location = NSNumber(value: locationValue)
            self.updateWith(settings: self.settings)
        }

        if !newStatus {
            self.locationManager.stopUpdatingLocation()
            saveLocationValue(newStatus)
            completion(true, nil)
        } else {
            self.locationManager.isLocationUsageAllowed { locationUsageAllowed in
                if locationUsageAllowed {
                    self.locationManager.startUpdatingLocation()
                    saveLocationValue(true)
                    completion(true, nil)
                } else {
                    saveLocationValue(false)
                    completion(false, NSError(domain: "Location is disabled", code: 666))
                }
            }
        }
    }

    func changeSendReadStatusTo(_ newStatus: Bool) {
        self.setSettingsParameterValue(value: newStatus,
                                       getter: { return self.settings?.sendRead?.boolValue ?? false },
                                       setter: { newValue in self.settings.sendRead = NSNumber(value: newValue) })
    }

    func changeSoundStatusTo(_ newStatus: Bool) {
        self.setSettingsParameterValue(value: newStatus,
                                       getter: { return self.settings?.sounds?.boolValue ?? false },
                                       setter: { newValue in self.settings.sounds = NSNumber(value: newValue) })
    }

    func changeNotificationSoundTo(_ newStatus: Bool) {
        self.setSettingsParameterValue(value: newStatus,
                                       getter: { return self.settings?.notificationsSound?.boolValue ?? false },
                                       setter: { newValue in self.settings.notificationsSound = NSNumber(value: newValue) })
    }

    func changeVibrationStatusTo(_ newStatus: Bool) {
        self.setSettingsParameterValue(value: newStatus,
                                       getter: { return self.settings?.notificationsVibration?.boolValue ?? false },
                                       setter: { newValue in self.settings.notificationsVibration = NSNumber(value: newValue) })
    }

    func changeFlashStatusTo(_ newStatus: Bool) {
        self.setSettingsParameterValue(value: newStatus,
                                       getter: { return self.settings?.notificationsFlash?.boolValue ?? false  },
                                       setter: { newValue in self.settings.notificationsFlash = NSNumber(value: newValue) })
    }

    func clearChatHistory() {
        self.settingsEraser.clearChatHistoryWith(completion: nil)
    }

    func disableDevice() {
        self.settingsEraser.disableDeviceWith(completion: nil)
    }

}

extension SettingsInteractor: ChatsChangesHandler {
    func handleChatsChange(_ chats: [Dialog]) {
        var newBlockedChats = self.blockedChats
        for chat in chats {
            if chat.isBlocked() {
                if !newBlockedChats.contains(chat) { newBlockedChats.append(chat) }
            } else {
                if let chatIndex = newBlockedChats.index(of: chat) { newBlockedChats.remove(at: chatIndex) }
            }
        }
        if newBlockedChats != self.blockedChats {
            self.updateBlockedChats(newBlockedChats: newBlockedChats)
        }
    }
}