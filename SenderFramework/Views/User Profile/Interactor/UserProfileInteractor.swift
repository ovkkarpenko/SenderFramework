//
// Created by Roman Serga on 22/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserProfileInteractor: UserProfileInteractorProtocol {
    var presenter: UserProfilePresenterProtocol?
    var dataManager: UserProfileDataManagerProtocol

    private(set) var user: Owner! = nil

    init(dataManager: UserProfileDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        let user = self.dataManager.loadUser()
        self.updateWith(user: user)
    }

    func updateWith(user: Owner) {
        self.user = user
        self.presenter?.userWasUpdated(self.user)
    }

    func loadQRString() {
        self.dataManager.loadUserPhone { phone, _ in
            guard let phone = phone else { return }
            self.presenter?.qrStringWasLoaded(qrString: phone)
        }
    }
}

extension UserProfileInteractor: OwnerChangesHandler {
    func handleOwnerChange(_ owner: Owner) {
        self.updateWith(user: owner)
    }
}
