//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class CallRobotModule: ChatModule, CallRobotModuleProtocol {

    private weak var router: ChatRouterProtocol?

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  callRobotModel: CallRobotModelProtocol,
                                  forDelegate delegate: ChatModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            let chatID: String
            if let robotModelChatID = callRobotModel.chatID {
                chatID = robotModelChatID
            } else {
                chatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
            }
            let chatPresentationModel = ChatPresentationModel(chatID: chatID)
            self.router?.presenter?.interactor.updateWith(chatID: chatID)
            self.router?.presentViewWith(wireframe: wireframe,
                                         model: chatPresentationModel,
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
        let callRobotInteractor = CallRobotInteractor(dataManager: chatDataManager,
                                            messagesSender: messageManager,
                                            fmlActionsHandlerInteractor: fmlActionsHandlerInteractor,
                                            googleUserManager: nil)
        fmlActionsHandlerInteractor.delegate = callRobotInteractor
        fmlActionsHandlerInteractor.presenter = fmlActionsHandlerPresenter
        callRobotInteractor.callRobotModel = callRobotModel
        fmlActionsHandlerRouter.presenter = fmlActionsHandlerPresenter

        let chatRouter = ChatRouter(addToChatModule: self.addToChatModule,
                                    qrScannerModule: self.qrScannerModule,
                                    qrDisplayModule: self.qrDisplayModule,
                                    fmlActionsHandlerRouter: fmlActionsHandlerRouter,
                                    senderUI: self.senderUI)
        fmlActionsHandlerRouter.delegate = chatRouter

        let chatPresenter = ChatPresenter(interactor: callRobotInteractor,
                                          fmlActionsHandlerPresenter: fmlActionsHandlerPresenter,
                                          router: chatRouter)
        let chatID: String
        if let robotModelChatID = callRobotModel.chatID {
            chatID = robotModelChatID
        } else {
            chatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
        }
        let chatPresentationModel = ChatPresentationModel(chatID: chatID)
        callRobotInteractor.updateWith(chatID: chatPresentationModel.chatID)
        callRobotInteractor.presenter = chatPresenter
        MWCometParser.shared.forceOpenHandler = callRobotInteractor
        MWCometParser.shared.soundPlayer = callRobotInteractor
        SenderCore.shared().activeChatsCoordinator.addChat(callRobotInteractor)
        chatRouter.presenter = chatPresenter
        chatRouter.presentViewWith(wireframe: wireframe,
                                   model: chatPresentationModel,
                                   forDelegate: delegate,
                                   completion: completion)
        self.router = chatRouter
    }

    @objc override public func dismiss(completion: (() -> Void)?) {
        super.dismiss(completion: nil)
        self.router?.dismissView(completion: completion)
    }

    @objc override public func dismissWithChildModules(completion: (() -> Void)?) {
        super.dismissWithChildModules(completion: nil)
        self.router?.dismissAllViews(completion: completion)
    }
}

extension CallRobotModel {
    @objc static var activeDevices: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "devices", companyID: "sender")
        return callRobotModel
    }

    @objc static var topUpMobile: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "payMobile", companyID: "sender")
        return callRobotModel
    }

    @objc static var transferMobile: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "sendMoney", companyID: "sender")
        return callRobotModel
    }

    @objc static var wallet: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "wallet", companyID: "sender")
        return callRobotModel
    }

    @objc static var store: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "shop", companyID: "sender")
        return callRobotModel
    }

    @objc static var createRobot: CallRobotModel {
        let callRobotModel = CallRobotModel(robotID: "92535", companyID: "sender")
        return callRobotModel
    }
}
