//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class QRScannerViewController: UIViewController, QRScannerViewProtocol, QRScannerDelegate {

    var presenter: QRScannerPresenterProtocol?

    @IBOutlet weak var scanView: QRScanView! {
        didSet {
            self.scanView.delegate = self
        }
    }

    @IBOutlet weak var scanBorderImage: UIImageView! {
        didSet {
            scanBorderImage.image = UIImage(fromSenderFrameworkNamed: "_QR_scanning_borders")
        }
    }
    @IBOutlet weak var cameraNotAvailableView: UIView! {
        didSet {
            cameraNotAvailableView.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.viewWasLoaded()
        self.title = SenderFrameworkLocalizedString("qr_title_scan")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            SenderCore.shared().stylePalette.customize(navigationController.navigationBar)
        }
        self.startScanning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopScanning()
    }

    func startScanning() {
        self.scanView.startRunning()
    }

    func stopScanning() {
        self.scanView.stopRunning()
    }

    func showCameraNotAvailableError(completion: (() -> Void)?) {
        self.cameraNotAvailableView.isHidden = false
        completion?()
    }

    func showSuccess(completion: (() -> Void)?) {
        completion?()
    }

    func scanViewDidDecodedData(_ data: String!) {
        self.presenter?.stringWasScanned(data)
    }

    @objc func cancelScanning() {
        self.presenter?.closeQRScanner()
    }
}

extension QRScannerViewController: ModalInNavigationWireframeEventsHandler {

    @objc func prepareForPresentationWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                          target: self,
                                          action: #selector(QRScannerViewController.cancelScanning))
        self.navigationItem.setLeftBarButton(closeButton, animated: false)
    }

    @objc func prepareForDismissalWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
    }
}
