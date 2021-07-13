//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class TermsConditionsPresenter: TermsConditionsPresenterProtocol {
    weak var view: TermsConditionsViewProtocol?
    weak var delegate: TermsConditionsModuleDelegate?
    var router: TermsConditionsRouterProtocol?
    var interactor: TermsConditionsInteractorProtocol

    init(interactor: TermsConditionsInteractorProtocol, router: TermsConditionsRouterProtocol?) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func termsConditionsTextWasUpdated(text: NSAttributedString) {
        self.view?.textWasUpdated(text: text)
    }

    func accept() {
        self.delegate?.termsConditionsModuleDidAccept()
    }

    func decline() {
        self.delegate?.termsConditionsModuleDidDecline()
    }

}
