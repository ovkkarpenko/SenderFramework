//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsInteractor: ChatSettingsInteractor,
                                     CompanyChatSettingsInteractorProtocol,
                                     FMLActionsHandlerInteractorDelegate {
    weak var presenter: CompanyChatSettingsPresenterProtocol? {
        didSet {
            self._presenter = self.presenter
        }
    }

    var dataManager: CompanyChatSettingsDataManagerProtocol {
        didSet { self._dataManager = self.dataManager }
    }

    var fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol

    init(dataManager: CompanyChatSettingsDataManagerProtocol,
         fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol) {
        self.dataManager = dataManager
        self.fmlActionsHandlerInteractor = fmlActionsHandlerInteractor
        super.init(dataManager: self.dataManager)
    }

    override func loadData() {
        super.loadData()
        if let cachedCompanyCard = self.chat.companyCard {
            self.presenter?.companyCardWasUpdated(cachedCompanyCard)
        }
        self.loadCompanyCard()
        self.dataManager.startMessagesChangesObservingWith(messagesChangesHandler: self)
    }

    override func updateWith(chat: Dialog) {
        self.fmlActionsHandlerInteractor.chat = chat
        super.updateWith(chat: chat)
    }

    func loadCompanyCard() {
        self.dataManager.loadCompanyCardFor(chat: self.chat, completion: nil)
    }

    func handleMessagesUpdate(_ updatedMessages: [Message]) {
        self.handleUpdatedMessages(updatedMessages)
    }

    func handleMessagesAdding(_ newMessages: [Message]) {
        self.handleUpdatedMessages(newMessages)
    }

    func handleMessagesRemoval(_ removedMessages: [Message]) {
        self.handleUpdatedMessages(removedMessages)
    }

    func handleUpdatedMessages(_ updatedMessages: [Message]) {
        let companyCards = updatedMessages.filter({ $0 == self.chat.companyCard }).flatMap({ $0 as? CompanyCard })
        companyCards.forEach { self.presenter?.companyCardWasUpdated($0) }
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
        guard !text.isEmpty, let user = self.chat.p2pContact else { return }
        self.dataManager.complainAbout(user: user, withText: text, completion: nil)
    }

    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     needsUpdatedChatWithID chatID: String) {
        let newChat = self.dataManager.chatWith(chatID: chatID)
        self.updateWith(chat: newChat)
    }

    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool {
        self.presenter?.callRobotWith(robotModel: callRobotModel)
        return false
    }
}
