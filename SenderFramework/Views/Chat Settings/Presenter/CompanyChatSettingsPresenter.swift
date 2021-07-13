//
// Created by Roman Serga on 9/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class CompanyChatSettingsPresenter: ChatSettingsPresenter, CompanyChatSettingsPresenterProtocol {
    weak var view: CompanyChatSettingsViewProtocol? {
        didSet { self._view = self.view }
    }

    var router: CompanyChatSettingsRouterProtocol? {
        didSet { self._router = self.router }
    }

    var interactor: CompanyChatSettingsInteractorProtocol {
        didSet { self._interactor = self.interactor }
    }
    var fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol

    init(interactor: CompanyChatSettingsInteractorProtocol,
         fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol,
         router: CompanyChatSettingsRouterProtocol?) {
        self.interactor = interactor
        self.fmlActionsHandlerPresenter = fmlActionsHandlerPresenter
        self.router = router
        super.init(interactor: interactor, router: router)
    }

    func loadCompanyCard() {
        self.interactor.loadCompanyCard()
    }

    func companyCardWasUpdated(_ companyCard: CompanyCard) {
        self.view?.updateWith(companyCard: companyCard)
    }

    func complaintWith(text: String) {
        self.interactor.complaintWith(text: text)
    }

    func changeIsDeletedStateTo(_ newIsDeleted: Bool) {
        self.interactor.changeIsDeletedStateTo(newIsDeleted)
    }
}
