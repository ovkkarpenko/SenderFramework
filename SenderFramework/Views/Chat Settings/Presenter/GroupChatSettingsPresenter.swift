//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GroupChatSettingsPresenter: ChatSettingsPresenter, GroupChatSettingsPresenterProtocol {
    weak var view: GroupChatSettingsViewProtocol? {
        didSet { self._view = self.view }
    }

    var router: GroupChatSettingsRouterProtocol? {
        didSet { self._router = self.router }
    }

    var interactor: GroupChatSettingsInteractorProtocol {
        didSet { self._interactor = self.interactor }
    }

    init(interactor: GroupChatSettingsInteractorProtocol, router: GroupChatSettingsRouterProtocol?) {
        self.interactor = interactor
        self.router = router
        super.init(interactor: interactor, router: router)
    }

    func deleteMember(_ member: ChatSettingsMemberViewModel) {
        self.interactor.deleteMember(member.member)
    }

    func editWith(name: String?, description: String?, image: UIImage?) {
        self.interactor.editWith(name: name, description: description, image: image)
    }

    func leaveChat() {
        self.interactor.leaveChat()
    }

    func goToChatWith(member: ChatSettingsMemberViewModel) {
        guard let chat = member.member.contact.p2pChat else { return }
        let shouldOpenChat = self.delegate?.chatSettingsPresenter(self, shouldOpenChat: chat, withActions: nil) ?? true
        guard shouldOpenChat else { return }
        self._router?.presentChatScreenWith(chat: chat, actions: nil)
    }
}
