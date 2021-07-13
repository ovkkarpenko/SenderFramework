//
// Created by Roman Serga on 14/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWChatEditManagerInput)
public class ChatEditManagerInput: NSObject, ChatEditManagerInputProtocol {

    @objc public func getInfoFor(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().getChatWithID(chatID, requestHandler: requestHandler)
    }

    @objc public func addMembersWith(userIDs: [String],
                                     toChatWithID chatID: String,
                                     requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().addMembers(userIDs, toChat: chatID, requestHandler: requestHandler)
    }

    @objc public func leaveChatWith(chatID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().leaveChat(chatID, completionHandler: requestHandler)
    }

    @objc public func edit(chatID: String,
                           withName name: String?,
                           description: String?,
                           imageURL: String?,
                           requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeChat(chatID,
                                                 withName: name,
                                                 description: description,
                                                 photoUrl: imageURL,
                                                 requestHandler: requestHandler)
    }

    @objc public func uploadChatImageData(_ imageData: Data, completion: @escaping ((URL?, Error?) -> Void)) {
        ServerFacade.sharedInstance().uploadData(imageData,
                                                 withFileExtension: "jpg",
                                                 target: "chat_logo",
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

    @objc public func sendReadFor(message: Message) {
        ServerFacade.sharedInstance().sayReadStatus(message)
    }

    @objc public func saveP2PChatWith(userID: String,
                                      requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().saveP2PChat(withUserID: userID, completionHandler: requestHandler)
    }

    @objc public func deleteP2PChatWith(userID: String, requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().deleteP2PChat(withUserID: userID, completionHandler: requestHandler)
    }

    @objc public func changeP2PChatWith(userID: String,
                                        name: String?,
                                        phone: String?,
                                        requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeP2PChat(withUserID: userID,
                                                    withName: name,
                                                    phone: phone,
                                                    completionHandler: requestHandler)
    }

    @objc public func changeSettingsOfChatWith(chatID: String,
                                               settingsDictionary: [String: Any],
                                               requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeSettingsOfChat(withID: chatID,
                                                           settingsDictionary: settingsDictionary,
                                                           withCompletionHandler: requestHandler)
    }

    @objc public func changeChatEncryptionStateWith(chatID: String,
                                                    encryptionState: Bool,
                                                    keys: [String: String]?,
                                                    senderKey: String?,
                                                    requestHandler: @escaping  SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().changeEncryptionStateOfChat(withID: chatID,
                                                                  encryptionState: encryptionState,
                                                                  keys: keys,
                                                                  senderKey: senderKey,
                                                                  completionHandler: requestHandler)
    }

    @objc public func deleteMembersWith(userIDs: [String],
                                        toChatWithID chatID: String,
                                        requestHandler: @escaping SenderRequestCompletionHandler) {
        ServerFacade.sharedInstance().deleteMembers(withUserIDs: userIDs,
                                                    fromChatWithID: chatID, requestHandler: requestHandler)
    }
}
