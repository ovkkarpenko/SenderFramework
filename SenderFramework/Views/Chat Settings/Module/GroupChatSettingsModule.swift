//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class GroupChatSettingsModule: ChatSettingsModule {
    private weak var groupChatSettingsRouter: GroupChatSettingsRouter?

    public override func createChatSettingsStackWith(chat: Dialog,
                                                     addToChatModule: AddToChatModuleProtocol,
                                                     senderUI: SenderUIProtocol) -> ChatSettingsStack {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatSettingsDataManager = GroupChatSettingsDataManager(input: chatEditManagerInput)
        let chatSettingsInteractor = GroupChatSettingsInteractor(dataManager: chatSettingsDataManager)
        let chatSettingsRouter = GroupChatSettingsRouter(addToChatModule: self.addToChatModule,
                                                         senderUI: self.senderUI)
        let chatSettingsPresenter = GroupChatSettingsPresenter(interactor: chatSettingsInteractor,
                                                             router: chatSettingsRouter)
        chatSettingsInteractor.presenter = chatSettingsPresenter
        chatSettingsInteractor.updateWith(chat: chat)
        chatSettingsRouter.presenter = chatSettingsPresenter
        chatSettingsPresenter.chatSettingsModule = self
        return (chatSettingsRouter, chatSettingsPresenter)
    }

    public override func senderUIWasSet() {
        super.senderUIWasSet()
        self.groupChatSettingsRouter?.senderUI = self.senderUI
    }
}
