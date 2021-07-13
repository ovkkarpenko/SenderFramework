//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWMessageManagerInput)
public class MessageManagerInput: NSObject, MessageManagerInputProtocol {
    public func sendTextMessage(_ message: Message,
                                toChat chat: Dialog,
                                completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendTextMessage(message, toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func sendStickerMessage(_ message: Message,
                                   toChat chat: Dialog,
                                   completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendStickerMessage(message, toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func sendAudioMessage(_ message: Message,
                                 toChat chat: Dialog,
                                 completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendAudioMessage(message, toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func sendVibroMessage(_ message: Message,
                                 toChat chat: Dialog,
                                 completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendVibroMessage(message, toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func uploadData(_ data: Data, withFileExtension fileExtension: String,
                           completion: ((String?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().uploadData(data,
                                                 withFileExtension: fileExtension,
                                                 target: "upload",
                                                 additionalData: nil) { response, error in
            guard error == nil else { completion?(nil, error); return }
            guard let url = response?["url"] as? String else {
                let noURLError = NSError(domain: "Response doesn't contain URL", code: 1)
                completion?(nil, noURLError)
                return
            }
            completion?(url, error)
        }
    }

    public func sendImageMessage(_ message: Message,
                                 withImageSize imageSize: CGSize,
                                 toChat chat: Dialog,
                                 completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendImageMessage(message,
                                                       withImageSize: imageSize,
                                                       toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func sendVideoMessage(_ message: Message,
                                 withVideoDuration duration: TimeInterval,
                                 toChat chat: Dialog,
                                 completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendVideoMessage(message,
                                                       withVideoDuration: duration,
                                                       toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    public func sendLocationMessage(_ message: Message,
                                    toChat chat: Dialog,
                                    completion: ((MessageSendingResult?, Error?) -> Void)?) {
        ServerFacade.sharedInstance().sendLocationMessage(message, toChat: chat) { response, error in
            guard error == nil else { completion?(nil, error); return }
            let (messageInfo, messageInfoError) = self.messageInfoFrom(response: response)
            guard let messageInfoUnwrapped = messageInfo else { completion?(nil, messageInfoError); return }
            guard let sendingResult = self.sendingResultFrom(messageInfo: messageInfoUnwrapped) else {
                let responseError = NSError(domain: "Wrong response", code: 666)
                completion?(nil, responseError)
                return
            }
            completion?(sendingResult, error)
        }
    }

    fileprivate func messageInfoFrom(response: [AnyHashable: Any]?) -> ([AnyHashable: Any]?, Error?) {
        guard let crResponse = (response?["cr"] as? [Any])?.first as? [AnyHashable: Any] else {
            let error = NSError(domain: "Cannot get response", code: 666)
            return (nil, error)
        }

        let crCode = crResponse["code"] as? Int
        guard crCode == nil || (crCode != nil && crCode! == 13) else {
            let crError = NSError(domain: "cr code is 13", code: 666)
            return (nil, crError)
        }

        return (crResponse, nil)
    }

    fileprivate func sendingResultFrom(messageInfo: [AnyHashable: Any]) -> MessageSendingResult? {
        guard let packetID = messageInfo["packetId"] as? Int,
              let creationTime = messageInfo["time"] as? Double else {
            return nil
        }
        let timeInterval = creationTime / 1000.0
        let creationDate = Date(timeIntervalSince1970: timeInterval)
        let sendingResult = MessageSendingResult(messageStatus: .sent,
                                                 packetID: String(packetID),
                                                 creationTime: creationDate)
        return sendingResult
    }
}
