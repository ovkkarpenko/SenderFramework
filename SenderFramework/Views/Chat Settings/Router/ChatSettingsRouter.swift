//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsRouter<ViewType>: ChatSettingsRouterProtocol
        where ViewType: UIViewController,
        ViewType: ChatSettingsViewProtocol {
    weak var _presenter: ChatSettingsPresenterProtocol?

    var addToChatModule: AddToChatModuleProtocol
    var senderUI: SenderUIProtocol

    weak var currentChatSettingsView: ViewType?
    var currentWireframe: ViewControllerWireframe?

    init(addToChatModule: AddToChatModuleProtocol, senderUI: SenderUIProtocol) {
        self.addToChatModule = addToChatModule
        self.senderUI = senderUI
    }

    var chatSettingsView: ViewType {
        if let existingView = self.currentChatSettingsView {
            return existingView
        } else {
            let newView = self.buildChatSettingsView()
            self.currentChatSettingsView = newView
            return newView
        }
    }

    func buildChatSettingsView() -> ViewType {
        fatalError("Method createContactView() must be overriden by subclasses of ContactPageRouter")
    }

    func prepareViewForPresentation(_ view: ViewType) {
        fatalError("Method prepareViewForPresentation(_:) must be overriden by subclasses of ContactPageRouter")
    }

    fileprivate func getViewAndPrepareForPresentationWith(delegate: ChatSettingsPresenterDelegate?) -> ViewType {
        let chatSettingsView = self.chatSettingsView
        self.prepareViewForPresentation(chatSettingsView)
        self._presenter?.delegate = delegate
        return chatSettingsView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: ChatSettingsPresenterDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentChatSettingsView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let chatSettingsView = self.getViewAndPrepareForPresentationWith(delegate: delegate)
        wireframe.presentView(chatSettingsView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let currentView = self.currentChatSettingsView else { return }
        self.currentWireframe?.dismissView(currentView, completion: completion)
    }

    func dismissAllViews(completion: (() -> Void)?) {
        self.addToChatModule.dismiss(completion: nil)
        self.dismissView(completion: completion)
    }

    func presentAddMemberScreenWith(chat: Dialog) {
        guard let currentSettingsView = currentChatSettingsView else { return }
        let wireframe = ModalInNavigationWireframe(rootView: currentSettingsView)
        self.addToChatModule.presentWith(wireframe: wireframe,
                                         chat: chat,
                                         allowsMultipleSelection: true,
                                         forDelegate: self._presenter,
                                         completion: nil)
    }

    func dismissAddMemberScreen() {
        self.addToChatModule.dismiss(completion: nil)
    }

    func presentChatScreenWith(chat: Dialog, actions: [[String: AnyObject]]?) {
        self.senderUI.showChatScreenWith(chat: chat,
                                         actions: actions,
                                         options: nil,
                                         animated: true,
                                         modally: false,
                                         delegate: nil)
    }

    func presentRobotScreenWith(callRobotModel: CallRobotModelProtocol) {
        self.senderUI.showRobotScreenWith(model: callRobotModel,
                                          animated: true,
                                          modally: false,
                                          delegate: nil)
    }
}
