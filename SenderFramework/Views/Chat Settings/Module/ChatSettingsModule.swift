//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class ChatSettingsModule: NSObject, ChatSettingsModuleProtocol, ChatSettingsPresenterDelegate {
    var addToChatModule: AddToChatModuleProtocol
    var senderUI: SenderUIProtocol {
        didSet {
            self.senderUIWasSet()
        }
    }

    private weak var delegate: ChatSettingsModuleDelegate?
    private weak var router: ChatSettingsRouterProtocol?

    @objc public init(addToChatModule: AddToChatModuleProtocol, senderUI: SenderUIProtocol) {
        self.addToChatModule = addToChatModule
        self.senderUI = senderUI
    }

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  chat: Dialog,
                                  forDelegate delegate: ChatSettingsModuleDelegate?,
                                  completion: (() -> Void)?) {
        self.delegate = delegate
        let (chatSettingsRouter, chatSettingsPresenter) = self.createChatSettingsStackWith(chat: chat,
                                                                                           addToChatModule: self.addToChatModule,
                                                                                           senderUI: self.senderUI)
        chatSettingsRouter.presentViewWith(wireframe: wireframe,
                                           forDelegate: (self.delegate != nil ? self : nil),
                                           completion: completion)
        self.router = chatSettingsRouter
    }

    public typealias ChatSettingsStack = (ChatSettingsRouterProtocol, ChatSettingsPresenterProtocol)

    open func createChatSettingsStackWith(chat: Dialog,
                                          addToChatModule: AddToChatModuleProtocol,
                                          senderUI: SenderUIProtocol) -> ChatSettingsStack {
        fatalError("createChatSettingsStackWith(chat:addToChatModule:senderUI:)" +
                           " must ber overriden in subclasses")
    }

    open func senderUIWasSet() {
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    @objc public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }

    public func chatSettingsPresenterDidUpdateChat(_ chat: Dialog) {
        self.delegate?.chatSettingsModuleDidUpdateChat(chat)
    }

    public func chatSettingsPresenter(_ chatSettingsPresenter: ChatSettingsPresenterProtocol,
                                      shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool {
        return self.delegate?.chatSettingsModule(self, shouldCallRobotWithModel: callRobotModel) ?? true
    }

    public func chatSettingsPresenter(_ chatSettingsPresenter: ChatSettingsPresenterProtocol,
                                      shouldOpenChat chat: Dialog,
                                      withActions actions: [[String: AnyObject]]?) -> Bool {
        return self.delegate?.chatSettingsModule(self,
                                                 shouldOpenChat: chat,
                                                 withActions: actions) ?? true
    }

    public func chatSettingsModuleDidFinish(_ chatSettingsPresenter: ChatSettingsPresenterProtocol) {
        self.delegate?.chatSettingsModuleDidFinish(self)
    }
}
