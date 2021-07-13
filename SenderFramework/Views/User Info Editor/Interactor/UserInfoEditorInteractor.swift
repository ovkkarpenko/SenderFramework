//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserInfoEditorInteractor: UserInfoEditorInteractorProtocol {
    weak var presenter: UserInfoEditorPresenterProtocol?

    private(set) var user: Owner!
    var dataManager: UserInfoEditorDataManagerProtocol

    init(dataManager: UserInfoEditorDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        let owner = self.dataManager.getOwner()
        self.updateWith(user: owner)
    }

    func updateWith(user: Owner) {
        self.user = user
        self.presenter?.userWasUpdated(user)
    }

    func editUserWith(name: String, description: String?, imageData: Data?) {
        guard !name.isEmpty else {
            self.presenter?.handleError(NSError(domain: "Cannot set empty name to user", code: 666))
            return
        }

        self.dataManager.edit(user: self.user,
                              withName: name,
                              description: description,
                              imageData: imageData) { user, error in
            guard error == nil else {
                self.presenter?.handleError(error ?? NSError(domain: "Cannot update user", code: 666))
                return
            }
            self.presenter?.finishEditingUser()
        }
    }
}

extension UserInfoEditorInteractor: OwnerChangesHandler {
    func handleOwnerChange(_ owner: Owner) {
        self.updateWith(user: owner)
    }
}
