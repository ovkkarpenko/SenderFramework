//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserInfoEditorPresenter: UserInfoEditorPresenterProtocol {

    weak var view: UserInfoEditorViewProtocol?
    weak var delegate: UserInfoEditorModuleDelegate?
    var router: UserInfoEditorRouterProtocol?
    var interactor: UserInfoEditorInteractorProtocol

    var newName: String = ""
    var newDescription: String?
    var newImageData: Data?

    init(interactor: UserInfoEditorInteractorProtocol, router: UserInfoEditorRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func userWasUpdated(_ user: Owner) {
        self.view?.updateWith(user: user)
    }

    func editUser() {
        self.interactor.editUserWith(name: self.newName,
                                     description: self.newDescription,
                                     imageData: self.newImageData)
    }

    func finishEditingUser() {
        self.delegate?.userInfoEditorModuleDidFinish()
    }

    func cancelEditingUser() {
        self.delegate?.userInfoEditorModuleDidCancel()
    }

    func handleError(_ error: Error) {
        self.view?.showInvalidDataError()
    }

    func loadOriginalUser() {
        self.interactor.loadData()
    }
}
