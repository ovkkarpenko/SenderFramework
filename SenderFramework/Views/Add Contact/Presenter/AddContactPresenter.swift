//
// Created by Roman Serga on 28/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddContactPresenter: AddContactPresenterProtocol {

    var interactor: AddContactInteractorProtocol
    weak var view: AddContactViewProtocol?
    weak var delegate: AddContactModuleDelegate?
    var router: AddContactRouterProtocol?

    init(interactor: AddContactInteractorProtocol) {
        self.interactor = interactor
    }

    convenience init(interactor: AddContactInteractorProtocol, router: AddContactRouterProtocol) {
        self.init(interactor: interactor)
        self.router = router
    }

    func addContactWith(name: String, phone: String) {
        self.interactor.addContactWith(name: name, phone: phone)
    }

    func cancelAddingContact() {
        self.delegate?.addContactPresenterDidCancel()
    }

    func finishAddingContact() {
        self.delegate?.addContactPresenterDidFinish()
    }

    func handleError(_ error: Error) {
        self.view?.showInvalidDataError()
    }

}
