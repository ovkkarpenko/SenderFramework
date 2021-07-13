//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class EntityPickerPresenter: EntityPickerPresenterProtocol {
    weak var view: EntityPickerViewProtocol?
    weak var delegate: EntityPickerModuleDelegate?
    var router: EntityPickerRouterProtocol?
    var interactor: EntityPickerInteractorProtocol

    init(interactor: EntityPickerInteractorProtocol, router: EntityPickerRouterProtocol? = nil) {
        self.interactor = interactor
        self.router = router
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func entityWasUpdated(_ entity: EntityViewModel) {
        self.view?.entityWasUpdated(entity)
    }

    func setNewEntities(_ newEntities: [EntityViewModel]) {
        self.view?.updateWith(entities: newEntities)
    }

    func selectEntity(_ entity: EntityViewModel) {
        self.interactor.selectEntity(entity)
    }

    func startFinishingPickingEntities() {
        self.interactor.finishPickingEntities()
    }

    func finishPickingEntitiesWith(selectedEntities: [EntityViewModel]) {
        self.delegate?.entityPickerModuleDidFinishWith(entities: selectedEntities)
    }

    func cancelPickingEntities() {
        self.delegate?.entityPickerModuleDidCancel()
    }

    func isEntitySelected(entity: EntityViewModel) -> Bool {
        return self.interactor.isEntitySelected(entity: entity)
    }

    func isMultipleSelectionAllowed() -> Bool {
        return self.interactor.allowsMultipleSelection
    }

    func handleNoUsersSelectedError() {
        self.view?.showNoUsersSelectedError()
    }

}