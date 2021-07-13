//
// Created by Roman Serga on 18/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatListPresenter: ChatListPresenterProtocol {

    weak var view: ChatListViewProtocol?
    weak var delegate: ChatListModuleDelegate?
    var router: ChatListRouterProtocol?
    var interactor: ChatListInteractorProtocol

    init(interactor: ChatListInteractorProtocol, router: ChatListRouterProtocol?) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func performMainAction() {
        self.delegate?.chatListDidPerformedMainAction()
    }

    func startAddingContact() {
        self.router?.showAddContactForm()
    }

    func addContactPresenterDidCancel() {
        self.router?.dismissAddContactForm()
    }

    func addContactPresenterDidFinish() {
        self.router?.dismissAddContactForm()
    }

    func showQRScanner() {
        self.router?.presentQRScanner()
    }

    func qrScannerModuleDidCancel() {
        self.router?.dismissQRScanner()
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.router?.dismissQRScanner()
    }

    func showChatWith(chatID: String, actions: [[String: AnyObject]]?) {
        self.router?.presentChatWith(chatID: chatID, actions: actions)
    }

    func showChatWith(chat: Dialog, actions: [[String: AnyObject]]?) {
        self.router?.presentChatWith(chat: chat, actions: actions)
    }

    func launchAction(_ action: ActionCellModel) {
        guard let classString = action.cellClass else { return }
        let callRobotModel = CallRobotModel(classString: classString)
        if let userID = action.cellUserID { callRobotModel.chatID = chatIDFromUserID(userID) }
        if let model = action.cellActionData { callRobotModel.model = model }
        self.router?.presentRobotScreenWith(callRobotModel: callRobotModel)
    }

    func handleIsSyncingState(_ isSyncing: Bool) {
        self.view?.setSyncIndicatorVisible(isSyncing)
    }
}
