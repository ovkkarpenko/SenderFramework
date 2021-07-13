//
// Created by Roman Serga on 17/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class QRDisplayInteractor: QRDisplayInteractorProtocol {
    weak var presenter: QRDisplayPresenterProtocol?
    private(set) var qrString: String!

    func loadData() {
        self.presenter?.qrStringWasUpdated(self.qrString)
    }

    func updateWith(qrString: String) {
        self.qrString = qrString
        self.presenter?.qrStringWasUpdated(self.qrString)
    }
}
