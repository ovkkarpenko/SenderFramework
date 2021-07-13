//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AddToChatRouter: EntityPickerRouter {

    weak var addToChatPresenter: AddToChatPresenterProtocol?
    private weak var currentEntityPickerView: ChatPickerOneCompanyViewController?
    private var currentWireframe: ViewControllerWireframe?

    override var entityPickerView: ChatPickerOneCompanyViewController {
        if let existingView = self.currentEntityPickerView {
            return existingView
        } else {
            let newView = self.buildEntityPickerView()
            self.currentEntityPickerView = newView
            return newView
        }
    }

    override func buildEntityPickerView() -> ChatPickerOneCompanyViewController {
        let storyboardName = "ChatPickerViewController"
        return ChatPickerOneCompanyViewController.loadFromSenderFrameworkStoryboardWith(name: storyboardName)
    }

    fileprivate func getViewAndPrepareForPresentationWith(moduleDelegate: AddToChatModuleDelegate?)
                    -> ChatPickerViewController {
        let entityPickerView = self.entityPickerView
        entityPickerView.presenter = self.addToChatPresenter
        self.addToChatPresenter?.addToChatView = entityPickerView
        self.addToChatPresenter?.addToChatDelegate = moduleDelegate
        return entityPickerView
    }

    func presentAddToChatViewWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: AddToChatModuleDelegate?,
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

    override func dismissView(completion: (() -> Void)?) {
        super.dismissView(completion: nil)
        guard let entityPickerView = self.currentEntityPickerView else { return }
        self.currentWireframe?.dismissView(entityPickerView, completion: completion)
    }
}
