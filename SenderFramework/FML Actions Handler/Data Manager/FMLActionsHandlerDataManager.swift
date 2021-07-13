//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class FMLActionsHandlerDataManager: FMLActionsHandlerDataManagerProtocol {
    public func uploadData(_ data: Data, completion: ((URL?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().uploadData(data,
                                                 withFileExtension: "jpg",
                                                 target: "upload",
                                                 additionalData: nil) { response, error in
            guard error == nil else { completion?(nil, error); return }
            guard let stringURL = response?["url"] as? String, let url = URL(string: stringURL) else {
                let noURLError = NSError(domain: "Response doesn't contain URL", code: 1)
                completion?(nil, noURLError)
                return
            }
            completion?(url, error)
        }
    }

    public func getSenderUsers() -> [Contact] {
        return CoreDataFacade.sharedInstance().getAllContacts()
    }

    public func getContacts() -> [Contact] {
        return CoreDataFacade.sharedInstance().getUsers()
    }

    public func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendQR(qrString,
                                             chatID: chatID,
                                             additionalParameters: nil) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }

    public func sendFormData(_ formData: [AnyHashable: Any], completion: ((Bool, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendForm(formData) { response, error in
            let success = response != nil && error == nil
            completion?(success, error)
        }
    }

    public func getOwnerBitcoinWallet() -> BitcoinWallet? {
        return try? CoreDataFacade.sharedInstance().getOwner().getMainWallet()
    }

    public func changeFullVersionStateTo(newFullVersionState: Bool, completion: ((Bool, Error?) -> Void)?) {
        SenderCore.shared().changeFullVersionState(newFullVersionState) { error in
            let success = error == nil
            completion?(success, error)
        }
    }

    public func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?) {
        var postData = [AnyHashable: Any]()
        postData["formId"] = model.formID ?? ""
        postData["robotId"] = model.robotID
        postData["companyId"] = model.companyID
        if let userID = model.userID {
            postData["userId"] = userID
        }

        let senderChatID = CoreDataFacade.sharedInstance().getOwner().senderChatId
        ServerFacade.sharedInstance().callRobot(withParameters: postData,
                                                chatID: model.chatID ?? senderChatID,
                                                withModel: model.model,
                                                requestHandler: completion)
    }
}
