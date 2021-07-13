//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class P2PChatSettingsRouter: ChatSettingsRouter<P2PSettingsViewController>, P2PChatSettingsRouterProtocol {
    weak var presenter: P2PChatSettingsPresenterProtocol? {
        didSet {
            self._presenter = self.presenter
        }
    }

    override func buildChatSettingsView() -> P2PSettingsViewController {
        return P2PSettingsViewController()
    }

    override func prepareViewForPresentation(_ view: P2PSettingsViewController) {
        view.presenter = self.presenter
        self.presenter?.view = chatSettingsView
    }
}
