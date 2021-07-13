//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsViewController: ChatSettingsViewController,
                                         CompanyChatSettingsViewProtocol {

    var presenter: CompanyChatSettingsPresenterProtocol? {
        didSet { self._presenter = self.presenter }
    }
    var fmlActionsHandlerView: FMLActionsHandlerViewProtocol
    weak var reportUserView: UIView?

    override init() {
        let fmlActionsHandlerView = FMLActionsHandlerView()
        self.fmlActionsHandlerView = fmlActionsHandlerView
        super.init()
        fmlActionsHandlerView.viewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        let fmlActionsHandlerView = FMLActionsHandlerView()
        self.fmlActionsHandlerView = fmlActionsHandlerView
        super.init(coder: aDecoder)
        fmlActionsHandlerView.viewController = self
    }

    func updateWith(companyCard: CompanyCard) {
        let maxWidth = self.maxProfileViewWidth ?? 0.0
        let companyCardView = PBConsoleManager.buildConsoleView(fromDate: companyCard,
                                                                maxWidth: maxWidth,
                                                                delegate: self.fmlActionsHandlerView)
        companyCardView.translatesAutoresizingMaskIntoConstraints = false
        self.profileView = companyCardView
        if let chat = self.chat { self.updateWith(viewModel: chat) }
    }

    override func openMoreMenu() {
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
            actions = [deleteAction, complainAction, blockAction, cancelAction]
        } else {
            if isDeletableChat {
                actions = [complainAction, blockAction, deleteAction, cancelAction]
            } else {
                actions = [complainAction, blockAction, cancelAction]
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

    func showShareScreenWith(items: [Any]) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.mw_safePresentIn(viewController: self, animated: true)
    }

    func showInfoWithText(_ infoText: String) {
        let alert = UIAlertController(title: nil,
                                      message: infoText,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: self, animated: true)
    }
}

extension CompanyChatSettingsViewController: ComplainPopUpDelegate {
    func complainPopUpDidFinishEnteringText(_ reportText: String!) {
        self.reportUserView?.removeFromSuperview()
        guard let complainText = reportText else { return }
        self.sendComplainWith(text: complainText)
    }
}
