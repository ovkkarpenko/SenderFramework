//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class P2PChatSettingsPresenter: ChatSettingsPresenter, P2PChatSettingsPresenterProtocol {
    weak var view: P2PChatSettingsViewProtocol? {
        didSet {
            self._view = self.view
        }
    }

    var router: P2PChatSettingsRouterProtocol? {
        didSet {
            self._router = self.router
        }
    }

    var interactor: P2PChatSettingsInteractorProtocol {
        didSet {
            self._interactor = self.interactor
        }
    }

    init(interactor: P2PChatSettingsInteractorProtocol, router: P2PChatSettingsRouterProtocol?) {
        self.interactor = interactor
        self.router = router
        super.init(interactor: interactor, router: router)
    }

    func editChatWith(name: String) {
        self.interactor.editChatWith(name: name)
    }

    func changeIsDeletedStateTo(_ newIsDeleted: Bool) {
        self.interactor.changeIsDeletedStateTo(newIsDeleted)
    }

    func complaintWith(text: String) {
        self.interactor.complaintWith(text: text)
    }

    func topUpMobile() {
        let topUpModel: CallRobotModel = .topUpMobile
        topUpModel.chatID = self.interactor.chat.chatID
        guard self.delegate?.chatSettingsPresenter(self, shouldCallRobotWithModel: topUpModel) ?? true else { return }
        self.router?.presentRobotScreenWith(callRobotModel: topUpModel)
    }

    func transfer() {
        let topUpModel: CallRobotModel = .transferMobile
        topUpModel.chatID = self.interactor.chat.chatID
        guard self.delegate?.chatSettingsPresenter(self, shouldCallRobotWithModel: topUpModel) ?? true else { return }
        self.router?.presentRobotScreenWith(callRobotModel: topUpModel)
    }

    func writeToChat() {
        self.goToChatWith(actions: nil)
    }
}
