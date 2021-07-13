//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddToChatInteractor: EntityPickerInteractor, AddToChatInteractorProtocol {
    var addToChatPresenter: AddToChatPresenterProtocol? { didSet { self.presenter = self.addToChatPresenter } }
    private(set) var chat: Dialog!
    var dataManager: AddToChatDataManagerProtocol
    var selectedCompany: EntityViewModel?

    init(dataManager: AddToChatDataManagerProtocol) {
        self.dataManager = dataManager
        super.init(allowsMultipleSelection: true)
    }

    func updateWith(chat: Dialog) {
        self.chat = chat
    }

    override func loadData() {
        self.dataManager.loadEntities { chats in
            let membersContacts = self.chat.membersContacts()
            let includeCompanies = membersContacts.filter({$0.isCompany?.boolValue ?? false}).isEmpty
            let chatMembersIDs = membersContacts.flatMap({return $0.userID})
            let entityModels = chats.flatMap { chat -> ChatListChatViewModel? in
                guard includeCompanies || chat.chatType != .company else { return nil }
                //Not showing p2p chats with members of chat we adding to
                guard let userID = userIDFromChatID(chat.chatID), !chatMembersIDs.contains(userID) else { return nil }
                return ChatListChatViewModel(chat: chat)
            }
            self.updateWith(entities: entityModels)
        }
    }

    override func selectEntity(_ entity: EntityViewModel) {
        let isCompanyEntity = (entity.chatType == .company)
        guard selectedCompany == nil || entity.chatType != .company || entity.isEqual(self.selectedCompany) else {
            self.addToChatPresenter?.handleOnlyOneCompanyError()
            return
        }

        super.selectEntity(entity)

        if isCompanyEntity {
            self.selectedCompany = self.isEntitySelected(entity: entity) ? entity : nil
        }
    }

    override func performAddingEntities(entities: [EntityViewModel]) {
        let members = entities.flatMap { ($0 as? ChatListChatViewModel)?.chat }
        self.dataManager.add(members: members,
                             toChat: self.chat) { chat, error in
            guard let newChat = chat, error == nil else {
                self.addToChatPresenter?.handleAddingToChatError()
                return
            }
            self.addToChatPresenter?.finishAddingToChatWith(newChat: newChat, selectedEntities: entities)
        }
    }
}
