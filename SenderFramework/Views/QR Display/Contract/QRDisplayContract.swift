//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol QRDisplayViewProtocol: class {
    var presenter: QRDisplayPresenterProtocol? { get set }
    func updateWith(qrString: String)
}

@objc public protocol QRDisplayModuleDelegate: class {
    func qrDisplayModuleDidCancel()
}

@objc public protocol QRDisplayPresenterProtocol: class {
    weak var view: QRDisplayViewProtocol? { get set }
    weak var delegate: QRDisplayModuleDelegate? { get set }

    var router: QRDisplayRouterProtocol? { get set }
    var interactor: QRDisplayInteractorProtocol { get set }

    func viewWasLoaded()

    func closeQRDisplay()

    func qrStringWasUpdated(_ qrString: String)
}

@objc public protocol QRDisplayRouterProtocol: class {
    weak var presenter: QRDisplayPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: QRDisplayModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

protocol ChildQRDisplayRouterProtocol: QRDisplayRouterProtocol {
    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: QRDisplayModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}

@objc public protocol QRDisplayInteractorProtocol: class {
    weak var presenter: QRDisplayPresenterProtocol? { get set }
    var qrString: String! { get }

    func loadData()

    func updateWith(qrString: String)
}

@objc public protocol QRDisplayModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     qrString: String,
                     forDelegate delegate: QRDisplayModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}

public protocol ChildQRDisplayModuleProtocol: QRDisplayModuleProtocol {
    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       qrString: String,
                                                       forDelegate delegate: QRDisplayModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}