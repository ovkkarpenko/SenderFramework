//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GroupChatSettingsRouter: ChatSettingsRouter<GroupChatSettingsViewController>, GroupChatSettingsRouterProtocol {
    weak var presenter: GroupChatSettingsPresenterProtocol? {
        didSet {
            self._presenter = self.presenter
        }
    }

    override func buildChatSettingsView() -> GroupChatSettingsViewController {
        return GroupChatSettingsViewController()
    }

    override func prepareViewForPresentation(_ view: GroupChatSettingsViewController) {
        view.presenter = self.presenter
        self.presenter?.view = chatSettingsView
    }

    override func dismissAllViews(completion: (() -> Void)?) {
        super.dismissAllViews(completion: completion)
    }
}
