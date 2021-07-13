//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol QRScreenViewProtocol: class {
    var presenter: QRScreenPresenterProtocol? { get set }
    func updateWith(state: QRScreenState)
}

@objc public protocol QRScreenModuleDelegate: class {
    func qrScreenModuleDidCancel()
}

protocol QRScreenPresenterProtocol: class, QRScannerModuleDelegate, QRDisplayModuleDelegate {

    weak var view: QRScreenViewProtocol? { get set }
    weak var delegate: QRScreenModuleDelegate? { get set }
    var interactor: QRScreenInteractorProtocol { get set }
    var router: QRScreenRouterProtocol? { get set }

    func viewWasLoaded()
    func changeViewState()
    func closeQRScreen()

    func stateWasUpdated(_ newState: QRScreenState)
}

@objc public protocol QRScreenModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     qrString: String,
                     forDelegate delegate: QRScreenModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}

protocol QRScreenRouterProtocol: class {

    func showQRScanner()
    func showQRImage()

    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           qrString: String,
                                                           forDelegate delegate: QRScreenModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
    func presentViewWith(wireframe: ViewControllerWireframe,
                         qrString: String,
                         forDelegate delegate: QRScreenModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

@objc enum QRScreenState: Int {
    case scanning
    case displayingQR
}

protocol QRScreenInteractorProtocol: class
{
    weak var presenter: QRScreenPresenterProtocol? { get set }
    var state: QRScreenState { get }

    func setInitialState()
    func changeState()
}
