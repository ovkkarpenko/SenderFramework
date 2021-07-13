//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddToChatPresenter: EntityPickerPresenter, AddToChatPresenterProtocol {

    weak var addToChatDelegate: AddToChatModuleDelegate? { didSet { self.delegate = self.addToChatDelegate }}
    weak var addToChatView: AddToChatViewProtocol? { didSet { self.view = addToChatView } }

    func handleOnlyOneCompanyError() {
        self.addToChatView?.showOnlyOneCompanyError()
    }

    func handleAddingToChatError() {
        self.addToChatView?.showCannotAddToChatError()
    }

    func finishAddingToChatWith(newChat: Dialog, selectedEntities: [EntityViewModel]) {
        self.addToChatDelegate?.addToChatModuleDidFinishWith(newChat: newChat, selectedEntities: selectedEntities)
    }

}