//
// Created by Roman Serga on 3/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddContactInteractor: AddContactInteractorProtocol {
    weak var presenter: AddContactPresenterProtocol?
    var dataManager: AddContactDataManagerProtocol

    init(dataManager: AddContactDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func addContactWith(name: String, phone: String) {
        let phoneTrimmed = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "")
        do {
            try self.validatePhone(phoneTrimmed)
            try self.validateName(name)
        } catch let error as NSError {
            self.presenter?.handleError(error)
            return
        }

        self.dataManager.addContactWith(name: name, phone: phoneTrimmed) { response, error in
            guard error == nil else {
                self.presenter?.handleError(error!)
                return
            }

            self.presenter?.finishAddingContact()
        }
    }

    func validatePhone(_ phone: String) throws {
        guard phone.replacingOccurrences(of: " ", with: "").lenght() > 0 else {
            throw NSError(domain: "Wrong phone format", code: 1)
        }
    }

    func validateName(_ name: String) throws {
        guard name.replacingOccurrences(of: " ", with: "").lenght() > 0 else {
            throw NSError(domain: "Wrong name format", code: 1)
        }
    }
}