//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatModule: NSObject, ChatModuleProtocol {

    private weak var router: ChatRouter?

    @objc public var addToChatModule: AddToChatModuleProtocol
    @objc public var entityPickerModule: EntityPickerModule
    @objc public var qrScannerModule: QRScannerModuleProtocol
    @objc public var qrDisplayModule: QRDisplayModule
    @objc public var termsConditionsModule: TermsConditionsModuleProtocol
    @objc public var senderUI: SenderUIProtocol {
        didSet {
            self.router?.senderUI = senderUI
        }
    }

    @objc public init(addToChatModule: AddToChatModuleProtocol,
                      entityPickerModule: EntityPickerModule,
                      qrScannerModule: QRScannerModuleProtocol,
                      qrDisplayModule: QRDisplayModule,
                      termsConditionsModule: TermsConditionsModuleProtocol,
                      senderUI: SenderUIProtocol) {
        self.addToChatModule = addToChatModule
        self.entityPickerModule = entityPickerModule
        self.qrScannerModule = qrScannerModule
        self.qrDisplayModule = qrDisplayModule
        self.termsConditionsModule = termsConditionsModule
        self.senderUI = senderUI
    }

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  model: ChatPresentationModelProtocol,
                                  forDelegate delegate: ChatModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presenter?.interactor.chat = model.chat
            self.router?.presentViewWith(wireframe: wireframe,
                                         model: model,
                                         forDelegate: delegate,
                                         completion: completion)
            return
        }

        let chatEditManagerInput = ChatEditManagerInput()
        let chatDataManager = ChatDataManager(input: chatEditManagerInput)
        let messageManagerInput = MessageManagerInput()
        let messageManagerDataStore = MessageManagerDataStore()
        let messageManager = MessageManager(input: messageManagerInput, dataStore: messageManagerDataStore)
        let googleUserManager = GoogleUserManager()

        let fmlActionsHandlerDataManager = FMLActionsHandlerDataManager()
        let fmlActionsHandlerInteractor = FMLActionsHandlerInteractor(dataManager: fmlActionsHandlerDataManager,
                                                                      googleUserManager: googleUserManager)
        let fmlActionsHandlerRouter = FMLActionsHandlerRouter(entityPickerModule: entityPickerModule,
                                                              qrScannerModule: qrScannerModule,
                                                              qrDisplayModule: qrDisplayModule,
                                                              termsConditionsModule: termsConditionsModule)
        let fmlActionsHandlerPresenter = FMLActionsHandlerPresenter(interactor: fmlActionsHandlerInteractor,
                                                                    router: fmlActionsHandlerRouter)
        let chatInteractor = ChatInteractor(dataManager: chatDataManager,
                                            messagesSender: messageManager,
                                            fmlActionsHandlerInteractor: fmlActionsHandlerInteractor,
                                            googleUserManager: nil)
        fmlActionsHandlerInteractor.delegate = chatInteractor
        fmlActionsHandlerInteractor.presenter = fmlActionsHandlerPresenter

        let chatRouter = ChatRouter(addToChatModule: self.addToChatModule,
                                    qrScannerModule: self.qrScannerModule,
                                    qrDisplayModule: self.qrDisplayModule,
                                    fmlActionsHandlerRouter: fmlActionsHandlerRouter,
                                    senderUI: self.senderUI)
        fmlActionsHandlerRouter.delegate = chatRouter
        fmlActionsHandlerRouter.presenter = fmlActionsHandlerPresenter

        let chatPresenter = ChatPresenter(interactor: chatInteractor,
                                          fmlActionsHandlerPresenter: fmlActionsHandlerPresenter,
                                          router: chatRouter)
        if let chat = model.chat {
            chatInteractor.updateWith(chat: chat)
        } else {
            chatInteractor.updateWith(chatID: model.chatID)
        }
        chatInteractor.sendBarDisabled = (model.options?[ChatPresentationModelOption.hideSendBar] as? Bool ?? false)
        chatInteractor.sendBarActions = model.actions
        chatInteractor.presenter = chatPresenter
        MWCometParser.shared.forceOpenHandler = chatInteractor
        MWCometParser.shared.soundPlayer = chatInteractor
        SenderCore.shared().activeChatsCoordinator.addChat(chatInteractor)
        chatRouter.presenter = chatPresenter
        chatRouter.presentViewWith(wireframe: wireframe, model: model, forDelegate: delegate, completion: completion)
        self.router = chatRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    @objc public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }
}

extension ChatInteractor: MWCometParserForceOpenHandler {
    @objc func cometParser(_ parser: MWCometParser, didReceiveForceOpenFormWith chatID: String) {
        self.updateWith(chatID: chatID)
    }
}

extension ChatInteractor: MWCometParserSoundPlayer {
    @objc func cometParser(_ parser: MWCometParser,
                           didReceiveMessage message: Message,
                           withData data: [String: AnyObject]) {
        guard !self.isActive || message.dialog.chatID != self.chatID else { return }
        SenderCore.shared().cometParser(parser, didReceiveMessage: message, withData: data)
    }
}
