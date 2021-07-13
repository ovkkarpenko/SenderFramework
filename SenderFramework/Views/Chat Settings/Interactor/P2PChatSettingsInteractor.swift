//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class P2PChatSettingsInteractor: ChatSettingsInteractor, P2PChatSettingsInteractorProtocol {
    weak var presenter: P2PChatSettingsPresenterProtocol? {
        didSet { self._presenter = self.presenter }
    }

    var dataManager: P2PChatSettingsDataManagerProtocol {
        didSet { self._dataManager = self.dataManager }
    }

    init(dataManager: P2PChatSettingsDataManagerProtocol) {
        self.dataManager = dataManager
        super.init(dataManager: self.dataManager)
    }

    func editChatWith(name: String) {
        self.dataManager.edit(p2pChat: self.chat,
                              withName: name,
                              phone: nil,
                              completionHandler: self.refreshPresenterWith)
    }

    func changeIsDeletedStateTo(_ newIsDeleted: Bool) {
        let oldIsDeleted = self.chat.chatState == .removed || self.chat.chatState == .inactive
        guard oldIsDeleted != newIsDeleted else { return }
        if newIsDeleted {
            self.dataManager.delete(chat: self.chat, completionHandler: self.refreshPresenterWith)
        } else {
            self.dataManager.save(p2pChat: self.chat, completionHandler: self.refreshPresenterWith)
        }
    }

    func complaintWith(text: String) {
        guard let user = self.chat.p2pContact else { return }
        self.dataManager.complainAbout(user: user, withText: text, completion: nil)
    }
}
