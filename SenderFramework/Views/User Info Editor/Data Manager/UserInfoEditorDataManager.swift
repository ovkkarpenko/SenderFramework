 //
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class UserInfoEditorDataManager: UserInfoEditorDataManagerProtocol {

    /*
         Using nil as description/imageData means "don't change this parameter".
         To delete description use "". To delete image, use empty image data
     */
    func edit(user: Owner,
              withName name: String?,
              description: String?,
              imageData: Data?,
              completionHandler: ((Owner?, Error?) -> Void)?) {

        let editClosure: (String) -> Void
        editClosure = { imageURLString in
            let userInfo = ["photo": imageURLString,
                            "name": name ?? "",
                            "description": description ?? ""]
            ServerFacade.sharedInstance().setSelfInfo(userInfo) { response, error in
                guard error == nil else { completionHandler?(nil, error); return }
                completionHandler?(user, nil)
            }
        }

        if let imageData = imageData {
            if !imageData.isEmpty {
                self.uploadChatImageData(imageData) { imageURL, error in
                    guard let url = imageURL else {
                        let error = NSError(domain: "Cannot get image URL. Server error", code: 1)
                        completionHandler?(nil, error)
                        return
                    }
                    editClosure(url.absoluteString)
                }
            } else {
                editClosure("")
            }
        } else {
            editClosure(user.ownimgurl ?? "")
        }
    }

    fileprivate func uploadChatImageData(_ imageData: Data, completion: @escaping ((URL?, Error?) -> Void)) {
        ServerFacade.sharedInstance().uploadData(imageData,
                                                 withFileExtension: "jpg",
                                                 target: "user_logo",
                                                 additionalData: nil) { response, error in
            guard error == nil else { completion(nil, error); return }

            guard let urlString = response?["url"] as? String, let url = URL(string: urlString) else {
                let error = NSError(domain: "Cannot get image URL", code: 1)
                completion(nil, error)
                return
            }
            completion(url, nil)
        }
    }

    func getOwner() -> Owner {
        return CoreDataFacade.sharedInstance().getOwner()
    }
}
