//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol EntityPickerViewProtocol: class {
    var presenter: EntityPickerPresenterProtocol? { get set }

    func entityWasUpdated(_ entity: EntityViewModel)
    func updateWith(entities: [EntityViewModel])

    func showNoUsersSelectedError()
}

@objc public protocol EntityPickerModuleDelegate: class {
    func entityPickerModuleDidCancel()
    func entityPickerModuleDidFinishWith(entities: [EntityViewModel])
}

@objc public protocol EntityPickerPresenterProtocol: class {
    weak var view: EntityPickerViewProtocol? { get set }
    weak var delegate: EntityPickerModuleDelegate? { get set }
    var router: EntityPickerRouterProtocol? { get set }
    var interactor: EntityPickerInteractorProtocol { get set }

    func viewWasLoaded()
    func entityWasUpdated(_ entity: EntityViewModel)
    func setNewEntities(_ newEntities: [EntityViewModel])

    func selectEntity(_ entity: EntityViewModel)
    func startFinishingPickingEntities()
    func cancelPickingEntities()

    func handleNoUsersSelectedError()
    func finishPickingEntitiesWith(selectedEntities: [EntityViewModel])

    func isMultipleSelectionAllowed() -> Bool
    func isEntitySelected(entity: EntityViewModel) -> Bool
}

@objc public protocol EntityPickerRouterProtocol: class {
    weak var presenter: EntityPickerPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: EntityPickerModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc public protocol EntityPickerInteractorProtocol: class {
    weak var presenter: EntityPickerPresenterProtocol? { get set }
    var entities: [EntityViewModel]! { get }
    var allowsMultipleSelection: Bool { get }

    func loadData()
    func updateWith(entities: [EntityViewModel])
    func selectEntity(_ entity: EntityViewModel)
    func isEntitySelected(entity: EntityViewModel) -> Bool
    func finishPickingEntities()
}

@objc public protocol EntityPickerModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     entityModels: [EntityViewModel],
                     allowsMultipleSelection: Bool,
                     forDelegate delegate: EntityPickerModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}