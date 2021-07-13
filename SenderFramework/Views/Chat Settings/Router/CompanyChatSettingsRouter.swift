//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsRouter: ChatSettingsRouter<CompanyChatSettingsViewController>,
                                 CompanyChatSettingsRouterProtocol,
                                 FMLActionsHandlerRouterDelegate {
    weak var presenter: CompanyChatSettingsPresenterProtocol? {
        didSet {
            self._presenter = self.presenter
        }
    }
    var fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol

    init(addToChatModule: AddToChatModuleProtocol,
         senderUI: SenderUIProtocol,
         fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol) {
        self.fmlActionsHandlerRouter = fmlActionsHandlerRouter
        super.init(addToChatModule: addToChatModule, senderUI: senderUI)
    }

    override func buildChatSettingsView() -> CompanyChatSettingsViewController {
        return CompanyChatSettingsViewController()
    }

    override func prepareViewForPresentation(_ view: CompanyChatSettingsViewController) {
        view.presenter = self.presenter
        view.fmlActionsHandlerView.presenter = self.presenter?.fmlActionsHandlerPresenter
        self.presenter?.view = chatSettingsView
        self.presenter?.fmlActionsHandlerPresenter.view = view.fmlActionsHandlerView
    }

    func fmlActionsHandlerRouterViewControllerForPresentation(_ fmlActionsHandlerRouter: FMLActionsHandlerRouter)
                    -> UIViewController? {
        return self.currentChatSettingsView
    }

    override func dismissAllViews(completion: (() -> Void)?) {
        self.fmlActionsHandlerRouter.dismissAllViews(completion: nil)
        super.dismissAllViews(completion: completion)
    }
}
