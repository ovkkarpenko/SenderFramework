//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class EntityPickerInteractor: EntityPickerInteractorProtocol {
    weak var presenter: EntityPickerPresenterProtocol?
    private(set) var entities: [EntityViewModel]!
    private var selectedEntities = NSMutableArray()
    private(set) var allowsMultipleSelection: Bool

    init(allowsMultipleSelection: Bool) {
        self.allowsMultipleSelection = allowsMultipleSelection
    }

    func loadData() {
        self.presenter?.setNewEntities(self.entities)
    }

    func updateWith(entities: [EntityViewModel]) {
        self.entities = entities
        self.presenter?.setNewEntities(self.entities)
    }

    func selectEntity(_ entity: EntityViewModel) {
        if !self.allowsMultipleSelection {
            self.presenter?.entityWasUpdated(entity)
            self.selectedEntities = [entity]
            self.finishPickingEntities()
            return
        } else {
            if self.isEntitySelected(entity: entity) {
                self.selectedEntities.remove(entity)
            } else {
                self.selectedEntities.add(entity)
            }
            self.presenter?.entityWasUpdated(entity)
        }
    }

    func isEntitySelected(entity: EntityViewModel) -> Bool {
        return self.selectedEntities.contains(entity)
    }

    func finishPickingEntities() {
        guard self.selectedEntities.count > 0 else {
            self.presenter?.handleNoUsersSelectedError()
            return
        }
        self.performAddingEntities(entities: self.selectedEntities as! [EntityViewModel])
    }

    func performAddingEntities(entities: [EntityViewModel]) {
        self.presenter?.finishPickingEntitiesWith(selectedEntities: entities)
    }
}
