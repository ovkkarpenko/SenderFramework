//
// Created by Roman Serga on 1/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class TermsConditionsDataManager: TermsConditionsDataManagerProtocol {

    func getFileURL() -> URL? {
        guard let senderFrameworkResourcesBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkResources bundle")
        }
        let fileName = SenderFrameworkLocalizedString("terms_file_name_ios")
        let fileURL = senderFrameworkResourcesBundle.url(forResource: fileName, withExtension: "rtf")
        return fileURL
    }

}
