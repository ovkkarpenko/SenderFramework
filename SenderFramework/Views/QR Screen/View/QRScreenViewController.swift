//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class QRScreenViewController: SubviewContainerViewController,
                              QRScreenViewProtocol,
                              ModalInNavigationWireframeEventsHandler {

    var presenter: QRScreenPresenterProtocol?

    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            actionButton.tintColor =  SenderCore.shared().stylePalette.controllerCommonBackgroundColor
            actionButton.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor
            actionButton.layer.cornerRadius = actionButton.frame.size.height / 2
            actionButton.layer.borderColor = actionButton.tintColor.cgColor
        }
    }
    @IBOutlet weak var actionTitleLabel: UILabel! {
        didSet { }
    }

    @IBAction func actionButtonPressed(_ sender: Any) {
        self.presenter?.changeViewState()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.viewWasLoaded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SenderCore.shared().stylePalette.customize(self.navigationController?.navigationBar)
    }

    private func customizeViewFor(state: QRScreenState) {
        let actionButtonTitle: String
        let actionButtonBorderWidth: CGFloat
        let actionButtonImage: UIImage?

        switch state {
            case .scanning:
                actionButtonTitle = SenderFrameworkLocalizedString("qr_title_my_code")
                actionButtonBorderWidth = 0
                actionButtonImage = UIImage(fromSenderFrameworkNamed: "_QR")
                self.title = SenderFrameworkLocalizedString("qr_title_scan")
            case .displayingQR:
                actionButtonTitle = SenderFrameworkLocalizedString("qr_title_scan")
                actionButtonBorderWidth = 1
                actionButtonImage = UIImage(fromSenderFrameworkNamed: "_QR_start_scanning")
                self.title = SenderFrameworkLocalizedString("qr_title_my_code")
        }

        self.actionTitleLabel.text = actionButtonTitle
        self.actionButton.layer.borderWidth = actionButtonBorderWidth
        self.actionButton.setImage(actionButtonImage, for: .normal)
    }

    func updateWith(state: QRScreenState) {
        self.customizeViewFor(state: state)
    }

    override func presentChildView(_ view: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.dismissChildView(view, animated: false, completion: nil)

        self.childViews.append(view)
        self.addChildViewController(view)

        self.view.insertSubview(view.view, belowSubview: self.actionButton)
        view.view.translatesAutoresizingMaskIntoConstraints = false
        let layoutAttributes: [NSLayoutAttribute] = [.top, .leading, .trailing, .bottom]
        for layoutAttribute in layoutAttributes {
            let constraint = NSLayoutConstraint(item: self.view,
                                                attribute: layoutAttribute,
                                                relatedBy: .equal,
                                                toItem: view.view,
                                                attribute: layoutAttribute,
                                                multiplier: 1.0,
                                                constant: 0.0)
            self.view.addConstraint(constraint)
        }

        if animated {
            let originalAlpha = view.view.alpha
            view.view.alpha = 0.0
            UIView.animate(withDuration: 0.3,
                           animations: { view.view.alpha = originalAlpha },
                           completion: { _ in completion?() })
        } else {
            completion?()
        }
    }

    @objc func cancelScanning() {
        self.presenter?.closeQRScreen()
    }

    func prepareForPresentationWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
        let closeButton = UIBarButtonItem(image: UIImage(fromSenderFrameworkNamed:"close"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(QRScreenViewController.cancelScanning))
        self.navigationItem.setLeftBarButton(closeButton, animated: false)
    }

    func prepareForDismissalWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
    }
}
