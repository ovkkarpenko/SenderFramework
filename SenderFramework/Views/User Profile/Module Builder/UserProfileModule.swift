//
// Created by Roman Serga on 4/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public class UserProfileModule: NSObject, UserProfileModuleProtocol {

    var qrScreenModule: QRScreenModuleProtocol

    public var senderUI: SenderUIProtocol {
        didSet {
            self.router?.senderUI = self.senderUI
        }
    }

    fileprivate weak var router: UserProfileRouter?

    @objc public init(qrScreenModule: QRScreenModuleProtocol, senderUI: SenderUIProtocol) {
        self.qrScreenModule = qrScreenModule
        self.senderUI = senderUI
    }

    @objc public func presentWith(wireframe: ViewControllerWireframe,
                                  forDelegate delegate: UserProfileModuleDelegate?,
                                  completion: (() -> Void)?) {
        guard self.router == nil else {
            self.router?.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
            return
        }
        let dataManager = UserProfileDataManager()
        let userProfileInteractor = UserProfileInteractor(dataManager: dataManager)
        let userProfileRouter = UserProfileRouter(qrScreenModule: self.qrScreenModule, senderUI: self.senderUI)
        let userProfilePresenter = UserProfilePresenter(interactor: userProfileInteractor, router: userProfileRouter)
        userProfileInteractor.presenter = userProfilePresenter
        userProfileRouter.presenter = userProfilePresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(userProfileInteractor)
        userProfileRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = userProfileRouter
    }

    @objc public func dismiss(completion: (() -> Void)?) {
        self.router?.dismissView(completion: completion)
    }

    @objc public func dismissWithChildModules(completion: (() -> Void)?) {
        self.router?.dismissAllViews(completion: completion)
    }

}

class ChildUserProfileModule: UserProfileModule, ChildUserProfileModuleProtocol {

        func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: UserProfileModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController {
        guard self.router as? ChildUserProfileRouterProtocol == nil else {
            (self.router as? ChildUserProfileRouterProtocol)?.presentViewWith(wireframe: wireframe,
                                                                              forDelegate: delegate,
                                                                              completion: completion)
            return
        }
        let dataManager = UserProfileDataManager()
        let userProfileInteractor = UserProfileInteractor(dataManager: dataManager)
        let userProfileRouter = ChildUserProfileRouter(qrScreenModule: self.qrScreenModule, senderUI: self.senderUI)
        let userProfilePresenter = UserProfilePresenter(interactor: userProfileInteractor, router: userProfileRouter)
        userProfileInteractor.presenter = userProfilePresenter
        userProfileRouter.presenter = userProfilePresenter
        SenderCore.shared().interfaceUpdater.addUpdatesHandler(userProfileInteractor)
        userProfileRouter.presentViewWith(wireframe: wireframe, forDelegate: delegate, completion: completion)
        self.router = userProfileRouter
    }

}
