//
// Created by Roman Serga on 15/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class EntityPickerRouter: EntityPickerRouterProtocol {

    weak var presenter: EntityPickerPresenterProtocol?
    private weak var currentEntityPickerView: ChatPickerViewController?
    private var currentWireframe: ViewControllerWireframe?

    var entityPickerView: ChatPickerViewController {
        if let existingView = self.currentEntityPickerView {
            return existingView
        } else {
            let newView = self.buildEntityPickerView()
            self.currentEntityPickerView = newView
            return newView
        }
    }

    func buildEntityPickerView() -> ChatPickerViewController {
        return ChatPickerViewController.loadFromSenderFrameworkStoryboardWith(name: "ChatPickerViewController")
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: EntityPickerModuleDelegate?)
                    -> ChatPickerViewController {
        let entityPickerView = self.entityPickerView
        entityPickerView.presenter = self.presenter
        self.presenter?.view = entityPickerView
        self.presenter?.delegate = moduleDelegate
        return entityPickerView
    }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: EntityPickerModuleDelegate?,
                         completion: (() -> Void)?) {
        guard self.currentEntityPickerView == nil || self.currentWireframe == nil else {
            let exception = NSException(name: .init("Cannot present view"),
                                        reason: "Presenting view that is already presented is not supported")
            exception.raise()
            return
        }
        let entityPickerView = self.getViewAndPrepareForPresentationWith(moduleDelegate: delegate)
        wireframe.presentView(entityPickerView, completion: completion)
        self.currentWireframe = wireframe
    }

    func dismissView(completion: (() -> Void)?) {
        guard let entityPickerView = self.currentEntityPickerView else { return }
        self.currentWireframe?.dismissView(entityPickerView, completion: completion)
    }

}
