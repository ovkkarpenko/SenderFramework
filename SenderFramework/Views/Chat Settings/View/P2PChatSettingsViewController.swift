//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class P2PSettingsViewController: ChatSettingsViewController, P2PChatSettingsViewProtocol {

    let profileViewActionIdentifierText = "profileViewActionIdentifierText"
    let profileViewActionIdentifierCall = "profileViewActionIdentifierCall"
    let profileViewActionIdentifierTransfer = "profileViewActionIdentifierTransfer"
    let profileViewActionIdentifierTopUp = "profileViewActionIdentifierTopUp"

    let doneEditingButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
    let cancelEditingButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)

    var p2pProfileView = P2PChatSettingsProfileView.mw_loadFromSenderFrameworkNibNamed("P2PChatSettingsProfileView") {
        didSet { self.profileView = p2pProfileView }
    }

    private(set) var isEditingUser: Bool = false

    override func viewDidLoad() {
        self.doneEditingButton.target = self
        self.doneEditingButton.action = #selector(finishEditing)

        self.cancelEditingButton.target = self
        self.cancelEditingButton.action = #selector(cancelEditing)

        self.setIsEditingUser(false, animated: false)
        self.p2pProfileView.delegate = self
        self.p2pProfileView.translatesAutoresizingMaskIntoConstraints = false
        self.p2pProfileView.backgroundColor = .white
        self.p2pProfileView.isDescriptionEditingEnabled = false
        self.profileView = self.p2pProfileView

        let textAction = P2PChatSettingsProfileViewAction(imageString: "💬",
                                                          title: SenderFrameworkLocalizedString("chat_settings_text"),
                                                          identifier: profileViewActionIdentifierText)

        let callAction = P2PChatSettingsProfileViewAction(imageString: "☎",
                                                          title: SenderFrameworkLocalizedString("chat_settings_call"),
                                                          identifier: profileViewActionIdentifierCall)

        let transferAction = P2PChatSettingsProfileViewAction(imageString: "💸",
                                                              title: SenderFrameworkLocalizedString("chat_settings_transfer"),
                                                              identifier: profileViewActionIdentifierTransfer)

        let topUpAction = P2PChatSettingsProfileViewAction(imageString: "📱",
                                                          title: SenderFrameworkLocalizedString("chat_settings_top_up"),
                                                          identifier: profileViewActionIdentifierTopUp)
        self.p2pProfileView.actions = [textAction, callAction, transferAction, topUpAction]

        super.viewDidLoad()
    }

    var presenter: P2PChatSettingsPresenterProtocol? {
        didSet { self._presenter = self.presenter }
    }

    override func updateWith(viewModel: ChatSettingsChatViewModel) {
        super.updateWith(viewModel: viewModel)
        if !self.isEditingUser { self.reloadProfileSectionWith(viewModel: viewModel) }
    }

    override func reloadProfileSectionWith(viewModel: ChatSettingsChatViewModel?) {
        guard !self.isEditingUser, let viewModel = viewModel else { return }
        self.p2pProfileView.nameTextField.text = viewModel.title
        self.p2pProfileView.descriptionTextField.text = viewModel.subtitle
        self.p2pProfileView.sd_cancelCurrentImageLoad()
        let placeholder = viewModel.defaultChatAvatarWith(size: self.p2pProfileView.imageView.frame.size, rounded: true)
        self.p2pProfileView.imageView.sd_setImage(with: viewModel.chatAvatarURL, placeholderImage: placeholder)
    }

    override func customizeNavigationBar() {
        super.customizeNavigationBar()
    }

    override func setNavigationBarButtons(animated: Bool) {
        super.setNavigationBarButtons(animated: animated)
        if self.isEditingUser {
            self.navigationItem.setRightBarButton(self.doneEditingButton, animated: animated)
            self.navigationItem.setLeftBarButton(self.cancelEditingButton, animated: animated)
        } else {
            self.navigationItem.setRightBarButton(self.moreButton, animated: animated)
            self.navigationItem.setLeftBarButton(self.leftBarButtonItem, animated: animated)
        }
    }

    func setIsEditingUser(_ isEditingUser: Bool, animated: Bool) {
        self.isEditingUser = isEditingUser
        self.p2pProfileView.isEditing = self.isEditingUser
        self.setNavigationBarButtons(animated: animated)
    }

    func showPhonesSelectionWith(phones: [ChatSettingsPhoneViewModel]) {
        var alertActions = phones.map { phoneViewModel in
            return UIAlertAction(title: phoneViewModel.phone,
                                 style: .default) { _ in self.presenter?.callPhone(phoneViewModel) }
        }
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel"), style: .cancel)

        alertActions.append(cancelAction)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertActions.forEach { alertController.addAction($0) }
        alertController.mw_safePresentIn(viewController: self, animated: true)
    }

    override func openMoreMenu() {
        let editAction = UIAlertAction(title: SenderFrameworkLocalizedString("edit"),
                                       style: .default) { _ in self.startEditing() }

        let complainAction = UIAlertAction(title: SenderFrameworkLocalizedString("complain_ios"),
                                       style: .default) { _ in self.complain() }

        let isBlockedChat = self.chat?.isBlocked ?? false
        let blockTitle = SenderFrameworkLocalizedString(isBlockedChat ? "chat_settings_unblock" : "chat_settings_block")
        let blockAction = UIAlertAction(title: blockTitle,
                                        style: .destructive) { _ in self.blockActionSelected() }

        let isDeletedChat = self.chat?.isDeleted ?? true
        let deleteTitle = SenderFrameworkLocalizedString(isDeletedChat ? "chat_settings_add_to_contacts" : "delete_ios")
        let deleteActionStyle: UIAlertActionStyle = isDeletedChat ? .default : .destructive
        let deleteAction = UIAlertAction(title: deleteTitle,
                                         style: deleteActionStyle) { _ in self.deleteActionSelected() }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel"), style: .cancel)

        let isDeletableChat = self.chat?.isDeletable ?? true
        let actions: [UIAlertAction]
        if isDeletedChat {
            actions = [deleteAction, editAction, complainAction, blockAction, cancelAction]
        } else {
            if isDeletableChat {
                actions = [editAction, complainAction, blockAction, deleteAction, cancelAction]
            } else {
                actions = [editAction, complainAction, blockAction, cancelAction]
            }
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.forEach { alertController.addAction($0) }
        alertController.mw_safePresentIn(viewController: self, animated: true)
    }

    func blockActionSelected() {
        guard let isBlocked = self.chat?.isBlocked else { return }
        self.presenter?.changeBlockStateTo(!isBlocked)
    }

    func deleteActionSelected() {
        guard let isDeleted = self.chat?.isDeleted else { return }
        self.presenter?.changeIsDeletedStateTo(!isDeleted)
    }

    weak var reportUserView: UIView?

    func complain() {
        guard let window = SenderCore.shared().window else { return }

        let reportUserView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        reportUserView.backgroundColor = UIColor.black.withAlphaComponent(0.0)

        let popUp = ComplainPopUp()
        popUp.delegate = self
        popUp.frame = CGRect(x: (window.frame.width - popUp.frame.size.width) / 2.0,
                             y: 60.0,
                             width: popUp.frame.size.width,
                             height: popUp.frame.size.height)
        reportUserView.addSubview(popUp)
        window.addSubview(reportUserView)

        UIView.animate(withDuration: 0.2, animations: {
            reportUserView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        })
        self.reportUserView = reportUserView
    }

    func sendComplainWith(text: String) {
        self.presenter?.complaintWith(text: text)
    }

    func startEditing() {
        self.setIsEditingUser(true, animated: true)
    }

    @objc func finishEditing() {
        self.setIsEditingUser(false, animated: true)
        self.presenter?.editChatWith(name: self.p2pProfileView.nameTextField.text ?? "")
    }

    @objc func cancelEditing() {
        self.setIsEditingUser(false, animated: true)
        if let chat = self.chat { self.updateWith(viewModel: chat) }
    }
}

extension P2PSettingsViewController: ComplainPopUpDelegate {
    func complainPopUpDidFinishEnteringText(_ reportText: String!) {
        self.reportUserView?.removeFromSuperview()
        guard let complainText = reportText else { return }
        self.sendComplainWith(text: complainText)
    }
}

extension P2PSettingsViewController: P2PChatSettingsProfileViewDelegate {
    func p2pChatSettingsProfileView(_ p2pChatSettingsProfileView: P2PChatSettingsProfileView,
                                    didSelectAction action: P2PChatSettingsProfileViewAction) {
        switch action.identifier {
        case profileViewActionIdentifierText: self.presenter?.writeToChat()
        case profileViewActionIdentifierCall:
            guard let phones = self.chat?.phoneNumbers else { break }
            if phones.count == 1, let firstPhone = phones.first {
                self.presenter?.callPhone(firstPhone)
            } else {
                self.showPhonesSelectionWith(phones: phones)
            }
            break
        case profileViewActionIdentifierTransfer: self.presenter?.transfer()
        case profileViewActionIdentifierTopUp: self.presenter?.topUpMobile()
        default: break
        }
    }
}
