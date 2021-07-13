//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class TermsConditionsInteractor: TermsConditionsInteractorProtocol {

    weak var presenter: TermsConditionsPresenterProtocol?

    var dataManager: TermsConditionsDataManagerProtocol

    init(dataManager: TermsConditionsDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadData() {
        guard let fileURL = self.dataManager.getFileURL() else {
            self.presenter?.termsConditionsTextWasUpdated(text: NSAttributedString())
            return
        }

        let text = try? NSAttributedString(fileURL: fileURL,
                                           options: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf],
                                           documentAttributes: nil)
        self.presenter?.termsConditionsTextWasUpdated(text: text ?? NSAttributedString())
    }

}
