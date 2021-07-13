//
//  P2PChatSettingsProfileView.swift
//  SenderFramework
//
//  Created by Roman Serga on 5/10/17.
//  Copyright © 2017 Middleware Inc. All rights reserved.
//

import UIKit

struct P2PChatSettingsProfileViewAction {
    var imageString: String?
    var title: String
    var identifier: String
}

class Weak<T: AnyObject> {
    weak var value: T?
    init (value: T) {
        self.value = value
    }
}

protocol P2PChatSettingsProfileViewDelegate: class {
    func p2pChatSettingsProfileView(_ p2pChatSettingsProfileView: P2PChatSettingsProfileView,
                                    didSelectAction action: P2PChatSettingsProfileViewAction)
}

class P2PChatSettingsProfileView: ChatSettingsProfileView {

    @IBOutlet weak var stackView: UIStackView! {
        didSet {
            self.stackView.spacing = 8.0
            self.stackView.alignment = .center
            self.stackView.distribution = .equalCentering
        }
    }

    weak var delegate: P2PChatSettingsProfileViewDelegate?

    var actionButtons: [Weak<P2PChatSettingsProfileActionButton>]?

    var actions: [P2PChatSettingsProfileViewAction]? {
        didSet {
            self.reloadStackView()
        }
    }

    func reloadStackView() {
        self.stackView.arrangedSubviews.forEach {
            self.stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let newActionButtons: [P2PChatSettingsProfileActionButton] = (self.actions ?? []).map { action in
            let nibName = "P2PChatSettingsProfileActionButton"
            let actionButton = P2PChatSettingsProfileActionButton.mw_loadFromSenderFrameworkNibNamed(nibName)
            actionButton.button.setTitle(action.imageString, for: .normal)
            actionButton.titleLabel.text = action.title
            actionButton.button.addTarget(self, action: #selector(actionButtonPressed(_:)), for: .touchUpInside)
            return actionButton
        }
        self.actionButtons = newActionButtons.map({ Weak(value: $0) })
        newActionButtons.forEach { self.stackView.addArrangedSubview($0) }
    }

    @objc func actionButtonPressed(_ actionButton: P2PChatSettingsProfileActionButton) {
        guard let actionButtons =  self.actionButtons,
              let buttonIndex = actionButtons.flatMap({ $0.value?.button }).index(of: actionButton),
              let action = self.actions?[buttonIndex] else { return }
        self.delegate?.p2pChatSettingsProfileView(self, didSelectAction: action)
    }
}
