//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class P2PChatSettingsModule: ChatSettingsModule {
    private weak var p2pChatSettingsRouter: P2PChatSettingsRouter?

    public override func createChatSettingsStackWith(chat: Dialog,
                                                     addToChatModule: AddToChatModuleProtocol,
                                                     senderUI: SenderUIProtocol) -> ChatSettingsStack {
        let chatEditManagerInput = ChatEditManagerInput()
        let chatSettingsDataManager = P2PChatSettingsDataManager(input: chatEditManagerInput)
        let chatSettingsInteractor = P2PChatSettingsInteractor(dataManager: chatSettingsDataManager)
        let chatSettingsRouter = P2PChatSettingsRouter(addToChatModule: self.addToChatModule, senderUI: self.senderUI)
        let chatSettingsPresenter = P2PChatSettingsPresenter(interactor: chatSettingsInteractor,
                                                             router: chatSettingsRouter)
        chatSettingsInteractor.presenter = chatSettingsPresenter
        chatSettingsInteractor.updateWith(chat: chat)
        chatSettingsRouter.presenter = chatSettingsPresenter
        chatSettingsPresenter.chatSettingsModule = self
        self.p2pChatSettingsRouter = chatSettingsRouter
        return (chatSettingsRouter, chatSettingsPresenter)
    }

    public override func senderUIWasSet() {
        super.senderUIWasSet()
        self.p2pChatSettingsRouter?.senderUI = self.senderUI
    }
}
