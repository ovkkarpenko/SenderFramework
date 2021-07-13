//
// Created by Roman Serga on 26/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol UserProfileViewProtocol: class {
    var presenter: UserProfilePresenterProtocol? { get set }
    func updateWith(user: Owner)
}

@objc (MWUserProfileModuleDelegate)
public protocol UserProfileModuleDelegate: class {
    func userProfileDidPerformedMainAction()
}

@objc public protocol UserProfilePresenterProtocol: class, QRScreenModuleDelegate {
    weak var view: UserProfileViewProtocol? { get set }
    weak var delegate: UserProfileModuleDelegate? { get set }
    var router: UserProfileRouterProtocol? { get set }
    var interactor: UserProfileInteractorProtocol { get set }

    func viewWasLoaded()

    func performMainAction()
    func showQRScreen()
    func topUpMobile()
    func transferMoney()
    func showWallet()
    func showStore()
    func createRobot()

    func userWasUpdated(_ user: Owner)

    func qrStringWasLoaded(qrString: String)
    func showSettings()
}

@objc public protocol UserProfileRouterProtocol: class {
    weak var presenter: UserProfilePresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: UserProfileModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func presentQRScreenWith(qrString: String)
    func dismissQRScreen()

    func presentSettings()

    func presentTopUpMobileScreen()
    func presentTransferMoneyScreen()
    func presentWalletScreen()
    func presentStoreScreen()
    func presentCreateRobotScreen()
}

public protocol ChildUserProfileRouterProtocol: UserProfileRouterProtocol {
    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: UserProfileModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}

@objc public protocol UserProfileInteractorProtocol: class {
    weak var presenter: UserProfilePresenterProtocol? { get set }

    var user: Owner! { get }

    func loadData()
    func updateWith(user: Owner)
    func loadQRString()
}

@objc public protocol UserProfileDataManagerProtocol: class {
    func loadUser() -> Owner
    func loadUserPhone(completion: ((String?, Error?) -> Void)?)
}

@objc public protocol UserProfileModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: UserProfileModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
}

public protocol ChildUserProfileModuleProtocol: UserProfileModuleProtocol {
    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       forDelegate delegate: UserProfileModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}