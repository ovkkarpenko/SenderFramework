//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsModule: ChatSettingsModule {
    @objc public var entityPickerModule: EntityPickerModule
    @objc public var qrScannerModule: QRScannerModuleProtocol
    @objc public var qrDisplayModule: QRDisplayModule
    @objc public var termsConditionsModule: TermsConditionsModuleProtocol

    private weak var companyChatSettingsRouter: CompanyChatSettingsRouter?

    init (entityPickerModule: EntityPickerModule,
          qrScannerModule: QRScannerModuleProtocol,
          qrDisplayModule: QRDisplayModule,
          termsConditionsModule: TermsConditionsModuleProtocol,
          addToChatModule: AddToChatModuleProtocol,
          senderUI: SenderUIProtocol) {
        self.entityPickerModule = entityPickerModule
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
        self.termsConditionsModule = termsConditionsModule
        super.init(addToChatModule: addToChatModule, senderUI: senderUI)
    }

    override func createChatSettingsStackWith(chat: Dialog,
                                              addToChatModule: AddToChatModuleProtocol,
                                              senderUI: SenderUIProtocol) -> ChatSettingsStack {
        let googleUserManager = GoogleUserManager()

        let fmlActionsHandlerDataManager = FMLActionsHandlerDataManager()
        let fmlActionsHandlerInteractor = FMLActionsHandlerInteractor(dataManager: fmlActionsHandlerDataManager,
                                                                      googleUserManager: googleUserManager)
        let fmlActionsHandlerRouter = FMLActionsHandlerRouter(entityPickerModule: self.entityPickerModule,
                                                              qrScannerModule: self.qrScannerModule,
                                                              qrDisplayModule: self.qrDisplayModule,
                                                              termsConditionsModule: self.termsConditionsModule)
        let fmlActionsHandlerPresenter = FMLActionsHandlerPresenter(interactor: fmlActionsHandlerInteractor,
                                                                    router: fmlActionsHandlerRouter)

        let chatEditManagerInput = ChatEditManagerInput()
        let chatSettingsDataManager = CompanyChatSettingsDataManager(input: chatEditManagerInput)
        let chatSettingsInteractor = CompanyChatSettingsInteractor(dataManager: chatSettingsDataManager,
                                                                   fmlActionsHandlerInteractor: fmlActionsHandlerInteractor)
        fmlActionsHandlerInteractor.delegate = chatSettingsInteractor
        fmlActionsHandlerInteractor.presenter = fmlActionsHandlerPresenter

        let chatSettingsRouter = CompanyChatSettingsRouter(addToChatModule: self.addToChatModule,
                                                           senderUI: self.senderUI,
                                                           fmlActionsHandlerRouter: fmlActionsHandlerRouter)
        fmlActionsHandlerRouter.delegate = chatSettingsRouter
        fmlActionsHandlerRouter.presenter = fmlActionsHandlerPresenter

        let chatSettingsPresenter = CompanyChatSettingsPresenter(interactor: chatSettingsInteractor,
                                                                 fmlActionsHandlerPresenter: fmlActionsHandlerPresenter,
                                                                 router: chatSettingsRouter)
        chatSettingsInteractor.presenter = chatSettingsPresenter
        chatSettingsInteractor.updateWith(chat: chat)
        chatSettingsRouter.presenter = chatSettingsPresenter
        chatSettingsPresenter.chatSettingsModule = self
        self.companyChatSettingsRouter = chatSettingsRouter
        return (chatSettingsRouter, chatSettingsPresenter)
    }

    override func senderUIWasSet() {
        super.senderUIWasSet()
        self.companyChatSettingsRouter?.senderUI = self.senderUI
    }
}
