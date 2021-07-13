//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol QRScannerViewProtocol: class {
    var presenter: QRScannerPresenterProtocol? { get set }

    func startScanning()
    func stopScanning()

    func showCameraNotAvailableError(completion: (() -> Void)?)
    func showSuccess(completion: (() -> Void)?)
}

@objc public protocol QRScannerModuleDelegate: class {
    func qrScannerModuleDidCancel()
    func qrScannerModuleDidFinishWith(string: String)
}

protocol QRScannerPresenterProtocol: class {
    weak var view: QRScannerViewProtocol? { get set }
    weak var delegate: QRScannerModuleDelegate? { get set }

    var router: QRScannerRouterProtocol? { get set }
    var interactor: QRScannerInteractorProtocol { get set }

    func viewWasLoaded()

    func stringWasScanned(_ string: String)

    func startScanning()
    func stopScanning()

    func closeQRScanner()
    func finishQRScannerWith(string: String)

    func handleCameraNotAvailableError()
}

protocol QRScannerRouterProtocol: class {
    weak var presenter: QRScannerPresenterProtocol? { get set }
    func presentViewWith(wireframe: ViewControllerWireframe,
                         forDelegate delegate: QRScannerModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
}

protocol ChildQRScannerRouterProtocol: QRScannerRouterProtocol {
    func presentViewWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                           forDelegate delegate: QRScannerModuleDelegate?,
                                                           completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}

protocol QRScannerInteractorProtocol: class {
    weak var presenter: QRScannerPresenterProtocol? { get set }

    func startWorking()
    func stringWasScanned(_ string: String)
}

@objc public protocol QRScannerModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     forDelegate delegate: QRScannerModuleDelegate?,
                     completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}

public protocol ChildQRScannerModuleProtocol: QRScannerModuleProtocol {
    func presentWith<WireframeType: WireframeProtocol>(wireframe: WireframeType,
                                                       forDelegate delegate: QRScannerModuleDelegate?,
                                                       completion: (() -> Void)?)
            where WireframeType.ChildViewType == UIViewController
}

protocol QRScannerCameraManagerProtocol {
    func requestCameraAccess(completion: @escaping ((Bool) -> Void))
}