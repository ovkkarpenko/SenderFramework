//
// Created by Roman Serga on 19/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRScreenInteractor: QRScreenInteractorProtocol {

    var state: QRScreenState
    weak var presenter: QRScreenPresenterProtocol?

    init(state: QRScreenState = .scanning) {
        self.state = .scanning
    }

    func setInitialState() {
        self.updateWith(state: state)
    }

    private func updateWith(state: QRScreenState) {
        self.state = state
        self.presenter?.stateWasUpdated(self.state)
    }

    func turnOnScanner() {
        self.updateWith(state: .scanning)
    }

    func turnOnQRImage() {
        self.updateWith(state: .displayingQR)
    }

    func changeState() {
        switch self.state {
            case .displayingQR: self.turnOnScanner()
            case .scanning: self.turnOnQRImage()
        }
    }
}
