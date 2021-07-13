//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWMessageSendingResult)
public class MessageSendingResult: NSObject {
    let messageStatus: MessageStatus
    let packetID: String
    let creationTime: Date

    init(messageStatus: MessageStatus, packetID: String, creationTime: Date) {
        self.messageStatus = messageStatus
        self.packetID = packetID
        self.creationTime = creationTime
    }
}

@objc(MWMessageManagerInputProtocol)
public protocol MessageManagerInputProtocol {
    func sendTextMessage(_ message: Message,
                         toChat chat: Dialog,
                         completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendStickerMessage(_ message: Message,
                            toChat chat: Dialog,
                            completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendAudioMessage(_ message: Message,
                          toChat chat: Dialog,
                          completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendVibroMessage(_ message: Message,
                          toChat chat: Dialog,
                          completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendImageMessage(_ message: Message,
                          withImageSize imageSize: CGSize,
                          toChat chat: Dialog,
                          completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendVideoMessage(_ message: Message,
                          withVideoDuration duration: TimeInterval,
                          toChat chat: Dialog,
                          completion: ((MessageSendingResult?, Error?) -> Void)?)

    func sendLocationMessage(_ message: Message,
                             toChat chat: Dialog,
                             completion: ((MessageSendingResult?, Error?) -> Void)?)

    func uploadData(_ data: Data, withFileExtension fileExtension: String, completion: ((String?, Error?) -> Void)?)
}

@objc(MWMessageManagerDataStoreProtocol)
public protocol MessageManagerDataStoreProtocol {
    func createOwnerTextMessageWith(text: String, inChat chat: Dialog) -> Message?
    func createOwnerStickerMessageWith(stickerID: String, inChat chat: Dialog) -> Message?
    func createOwnerAudioMessageWith(audioData: Data, inChat chat: Dialog) -> Message?
    func createOwnerVibroMessageIn(chat: Dialog) -> Message?
    func createOwnerImageMessageWith(imageData: Data,
                                     assetID: String,
                                     previewData: Data?,
                                     inChat chat: Dialog,
                                     completion: ((Message?, Error?) -> Void)?)
    func createOwnerVideoMessageWith(assetID: String,
                                     videoDuration: TimeInterval,
                                     previewData: Data?,
                                     inChat chat: Dialog) -> Message?
    func createOwnerLocationMessageWith(locationData: [AnyHashable: Any], inChat chat: Dialog) -> Message?

    func saveImageToPhotoAlbum(imageData: Data, completion: ((String?, Error?) -> Void)?)
    func saveVideoToPhotoAlbum(videoData: Data, completion: ((String?, Error?) -> Void)?)
    func imageWith(assetID: String, completion: ((UIKit.UIImage?, Error?) -> Void)?)
    func videoDataWith(assetID: String, completion: ((Data?, URL?, Error?) -> Void)?)
}

@objc(MWMessageManager)
public class MessageManager: NSObject, MessageSenderProtocol {

    public typealias MessageManagerCompletion = ((Message?, Error?) -> Void)

    var input: MessageManagerInputProtocol
    var dataStore: MessageManagerDataStoreProtocol

    init(input: MessageManagerInputProtocol, dataStore: MessageManagerDataStoreProtocol) {
        self.input = input
        self.dataStore = dataStore
    }

    func setText(_ text: String,
                 toMessage message: Message,
                 inChat chat: Dialog,
                 encryptionEnabled: Bool) -> (Message, Error?) {
        if encryptionEnabled && SenderCore.shared().isBitcoinEnabled {
            let oldMessageData = message.data
            message.data = ParamsFacade.sharedInstance().nsData(from: ["text": text, "pkey": ""])
            guard let encryptedMessage = MWMessagesCryptography.encryptMessage(message, chat: chat) else {
                let error = NSError(domain: "Cannot encrypt message", code: 666)
                message.data = oldMessageData
                return (message, error)
            }
            return (encryptedMessage, nil)
        } else {
            message.data = ParamsFacade.sharedInstance().nsData(from: ["text": text, "pkey": ""])
            message.encrypted = false
        }
        return (message, nil)
    }

    func deleteTextOf(message: Message) -> Message {
        message.data = ParamsFacade.sharedInstance().nsData(from: ["text": "", "pkey": ""])
        message.encrypted = false
        return message
    }

    func setUnsentStatusTo(chat: Dialog) {
        chat.lastMessageStatus = .unsent
        SenderCore.shared().interfaceUpdater.chatsWereChanged([chat])
    }

    /*
        When text to send is longer than 5000 characters, we send in as multiple messages.
        In this case completion will be called for each of sent messages
    */
    public func sendTextMessageWith(text: String,
                                    toChat chat: Dialog,
                                    encryptionEnabled: Bool,
                                    completion: MessageManagerCompletion?) {
        let (isValidChat, error) = self.validateChat(chat)
        guard isValidChat else { completion?(nil, error); return }

        var textToSend = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var restOfText: String?
        if textToSend.characters.count > 5000 {
            textToSend = text.substring(to:  textToSend.index(textToSend.startIndex, offsetBy: 5000))
            restOfText = text.substring(from: textToSend.index(textToSend.startIndex, offsetBy: 5000))
        }

        guard var message = self.dataStore.createOwnerTextMessageWith(text: textToSend, inChat: chat) else {
            let error = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, error)
            return
        }

        let (newMessage, settingTextError) = self.setText(textToSend,
                                                          toMessage: message,
                                                          inChat: chat,
                                                          encryptionEnabled: encryptionEnabled)
        message = newMessage
        self.setUnsentStatusTo(chat: chat)

        guard settingTextError == nil else { completion?(message, settingTextError!); return }

        self.input.sendTextMessage(message, toChat: chat) { sendingResult, error in
            guard error == nil else { completion?(message, error); return }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot send message", code: 666)
                completion?(message, error)
                return
            }
            _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
            completion?(message, error)
            if let restOfText = restOfText {
                self.sendTextMessageWith(text: restOfText,
                                         toChat: chat,
                                         encryptionEnabled: encryptionEnabled,
                                         completion: completion)
            }
        }
    }

    public func sendStickerMessageWith(stickerID: String,
                                       toChat chat: Dialog,
                                       completion: MessageManagerCompletion?) {
        let (isValidChat, error) = self.validateChat(chat)
        guard isValidChat else { completion?(nil, error); return }

        guard let message = self.dataStore.createOwnerStickerMessageWith(stickerID: stickerID, inChat: chat) else {
            let error = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, error)
            return
        }

        self.setUnsentStatusTo(chat: chat)

        self.input.sendStickerMessage(message, toChat: chat) { sendingResult, error in
            guard error == nil else { completion?(message, error); return }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot send message", code: 666)
                completion?(message, error)
                return
            }
            _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
            completion?(message, error)
        }
    }

    public func sendAudioMessageWith(audioData: Data,
                                     toChat chat: Dialog,
                                     completion: MessageManagerCompletion?) {
        let (isValidChat, error) = self.validateChat(chat)
        guard isValidChat else { completion?(nil, error); return }

        guard let message = self.dataStore.createOwnerAudioMessageWith(audioData: audioData, inChat: chat) else {
            let error = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, error)
            return
        }

        self.setUnsentStatusTo(chat: chat)

        self.input.uploadData(audioData, withFileExtension: "mp3") { stringURL, error in
            guard error == nil else { completion?(nil, error); return }
            guard let stringURL = stringURL, let remoteURL = NSURL.mw_URLByAddingPercentEscapes(to: stringURL) else {
                let noURLError = NSError(domain: "Response does not contain URL", code: 666)
                completion?(nil, noURLError)
                return
            }

            SenderFileManager.shared.saveData(audioData, withRemoteURL: remoteURL as URL) { audioURL, error in
                guard error == nil else { completion?(nil, error); return }
                guard let audioURL = audioURL else {
                    let saveError = NSError(domain: "Cannot save file with Server URL", code: 666)
                    completion?(nil, saveError)
                    return
                }

                message.file.localUrl = audioURL.absoluteString
                message.file.url = stringURL
                message.file.isDownloaded = true
                AudioRecorder().deleteFile()

                self.input.sendAudioMessage(message, toChat: chat) { sendingResult, error in
                    guard error == nil else { completion?(message, error); return }
                    guard let sendingResult = sendingResult else {
                        let error = NSError(domain: "Cannot send message", code: 666)
                        completion?(message, error)
                        return
                    }
                    _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
                    completion?(message, error)
                }
            }
        }
    }

    public func sendVibroMessageTo(chat: Dialog, completion: MessageManagerCompletion?) {
        let (isValidChat, error) = self.validateChat(chat)
        guard isValidChat else { completion?(nil, error); return }

        guard let message = self.dataStore.createOwnerVibroMessageIn(chat: chat) else {
            let error = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, error)
            return
        }

        self.setUnsentStatusTo(chat: chat)

        self.input.sendVibroMessage(message, toChat: chat) { sendingResult, error in
            guard error == nil else { completion?(message, error); return }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot send message", code: 666)
                completion?(message, error)
                return
            }
            _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
            completion?(message, error)
        }
    }

    public func sendImageMessageTo(chat: Dialog,
                                   assetID: String?,
                                   image: UIKit.UIImage?,
                                   completion: MessageManagerCompletion?) {
        if let assetID = assetID {
            self.sendImageMessageTo(chat: chat, assetID: assetID, image: image, completion: completion)
        } else if let image = image {
            self.sendImageMessageTo(chat: chat, assetID: assetID, image: image, completion: completion)
        } else {
            let error = NSError(domain: "Cannot send image when both assetID and image are nil", code: 666)
            completion?(nil, error)
        }
    }

    fileprivate func sendImageMessageTo(chat: Dialog,
                                        assetID: String,
                                        image: UIKit.UIImage?,
                                        completion: MessageManagerCompletion?) {
        guard let imageToSend = image else {
            self.dataStore.imageWith(assetID: assetID) { image, error in
                guard error == nil else { completion?(nil, error); return }
                guard let imageToSend = image else {
                    let getImageError = NSError(domain: "Cannot get image for given assetID", code: 666)
                    completion?(nil, getImageError)
                    return
                }
                self.sendImageMessageTo(chat: chat, assetID: assetID, image: imageToSend, completion: completion)
            }
            return
        }
        self.sendImageMessageTo(chat: chat, assetID: assetID, image: imageToSend, completion: completion)
    }

    fileprivate func sendImageMessageTo(chat: Dialog,
                                        assetID: String?,
                                        image: UIKit.UIImage,
                                        completion: MessageManagerCompletion?) {
        guard let assetID = assetID else {
            let imageEditor = MediaEditor()
            guard let imageData = imageEditor.dataRepresentationOf(image: image) else {
                let imageDataError = NSError(domain: "Cannot generate image data representation", code: 666)
                completion?(nil, imageDataError)
                return
            }
            self.dataStore.saveImageToPhotoAlbum(imageData: imageData) { assetID, error in
                guard error == nil else { completion?(nil, error); return }
                guard let assetID = assetID else {
                    let saveError = NSError(domain: "Cannot get assetID for saved image", code: 666)
                    completion?(nil, saveError)
                    return
                }
                self.sendImageMessageTo(chat: chat, assetID: assetID, image: image, completion: completion)
            }
            return
        }
        self.sendImageMessageTo(chat: chat, assetID: assetID, image: image, completion: completion)
    }

    fileprivate func sendImageMessageTo(chat: Dialog,
                                        assetID: String,
                                        image: UIKit.UIImage,
                                        completion: MessageManagerCompletion?) {
        let imageEditor = MediaEditor()
        let scaleRatio: CGFloat = CometController.sharedInstance().isWWAN() ? 4.0 : 2.0
        let compressionQuality: CGFloat = CometController.sharedInstance().isWWAN() ? 0.4 : 0.6
        let compressionResult = imageEditor.compressedImage(image,
                                                            withScaleRatio: scaleRatio,
                                                            compressionQuality: compressionQuality)
        guard let (compressedSize, compressedImage) = compressionResult else {
            let imageGenerationError = NSError(domain: "Cannot generate compressed image", code: 666)
            completion?(nil, imageGenerationError)
            return
        }

        func sendMessage(_ message: Message) {
            self.input.sendImageMessage(message,
                                        withImageSize: compressedSize,
                                        toChat: chat) { sendingResult, error in
                guard error == nil else { completion?(message, error); return }
                guard let sendingResult = sendingResult else {
                    let error = NSError(domain: "Cannot send message", code: 666)
                    completion?(message, error)
                    return
                }
                _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
                completion?(message, error)
            }
        }

        let previewImage = imageEditor.previewImageWith(image, imageSideLength: 400)

        DispatchQueue.main.async {
            self.dataStore.createOwnerImageMessageWith(imageData: compressedImage,
                                                       assetID: assetID,
                                                       previewData: previewImage,
                                                       inChat: chat) { message, error in
                guard error == nil else { completion?(nil, error); return }
                guard let message = message else {
                    let messageError = NSError(domain: "Cannot create image message", code: 666)
                    completion?(nil, messageError)
                    return
                }

                self.setUnsentStatusTo(chat: chat)

                self.input.uploadData(compressedImage, withFileExtension: "jpg") { urlString, imageUploadError in
                    guard imageUploadError == nil else { completion?(nil, imageUploadError); return }
                    guard let urlString = urlString else {
                        let noURLError = NSError(domain: "Response does not contain URL", code: 666)
                        completion?(nil, noURLError)
                        return
                    }
                    message.file.url = urlString
                    message.file.isDownloaded = true
                    if let previewData = previewImage {
                        self.input.uploadData(previewData, withFileExtension: "jpg") { previewURLString, _ in
                            message.file.prev_url = previewURLString
                            sendMessage(message)
                        }
                    } else {
                        sendMessage(message)
                    }
                }
            }
        }
    }

    public func sendVideoMessageTo(chat: Dialog,
                                   videoData: Data?,
                                   assetID: String?,
                                   duration: TimeInterval,
                                   completion: MessageManagerCompletion?) {
        if let assetID = assetID {
            self.sendVideoMessageTo(chat: chat,
                                    videoData: videoData,
                                    assetID: assetID,
                                    duration: duration,
                                    completion: completion)
        } else if let videoData = videoData {
            self.sendVideoMessageTo(chat: chat,
                                    videoData: videoData,
                                    assetID: assetID,
                                    duration: duration,
                                    completion: completion)
        } else {
            let error = NSError(domain: "Cannot send video when both videoData and assetID are nil", code: 666)
            completion?(nil, error)
        }
    }

    fileprivate func sendVideoMessageTo(chat: Dialog,
                                        videoData: Data?,
                                        assetID: String,
                                        duration: TimeInterval,
                                        completion: MessageManagerCompletion?) {
        guard let videoData = videoData else {
            self.dataStore.videoDataWith(assetID: assetID) { data, _, error in
                guard error == nil else { completion?(nil, error); return }
                guard let data = data else {
                    let getImageError = NSError(domain: "Cannot get video for assetID", code: 666)
                    completion?(nil, getImageError)
                    return
                }
                self.sendVideoMessageTo(chat: chat,
                                        videoData: data,
                                        assetID: assetID,
                                        duration: duration,
                                        completion: completion)
            }
            return
        }
        self.sendVideoMessageTo(chat: chat,
                                videoData: videoData,
                                assetID: assetID,
                                duration: duration,
                                completion: completion)
    }

    fileprivate func sendVideoMessageTo(chat: Dialog,
                                        videoData: Data,
                                        assetID: String?,
                                        duration: TimeInterval,
                                        completion: MessageManagerCompletion?) {
        guard let assetID = assetID else {
            let imageEditor = MediaEditor()
            self.dataStore.saveVideoToPhotoAlbum(videoData: videoData) { assetID, error in
                guard error == nil else { completion?(nil, error); return }
                guard let assetID = assetID else {
                    let saveError = NSError(domain: "Cannot get assetID for saved video", code: 666)
                    completion?(nil, saveError)
                    return
                }
                self.sendVideoMessageTo(chat: chat,
                                        videoData: videoData,
                                        assetID: assetID,
                                        duration: duration,
                                        completion: completion)
            }
            return
        }
        self.sendVideoMessageTo(chat: chat,
                                videoData: videoData,
                                assetID: assetID,
                                duration: duration,
                                completion: completion)
    }

    fileprivate func sendVideoMessageTo(chat: Dialog,
                                        videoData: Data,
                                        assetID: String,
                                        duration: TimeInterval,
                                        completion: MessageManagerCompletion?) {
        func sendMessage(_ message: Message) {
            self.input.sendVideoMessage(message,
                                        withVideoDuration: duration,
                                        toChat: chat) { sendingResult, error in
                guard error == nil else { completion?(message, error); return }
                guard let sendingResult = sendingResult else {
                    let error = NSError(domain: "Cannot send message", code: 666)
                    completion?(message, error)
                    return
                }
                _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
                completion?(message, error)
            }
        }

        self.dataStore.videoDataWith(assetID: assetID) { videoData, videoURL, error in
            guard error == nil else { completion?(nil, nil); return }
            guard let videoData = videoData, let videoURL = videoURL else {
                let error = NSError(domain: "Cannot get video for assetID", code: 666)
                completion?(nil, error)
                return
            }
            let mediaEditor = MediaEditor()
            mediaEditor.previewImageWith(videoURL: videoURL, imageSideLength: 400) { previewData, _ in
                DispatchQueue.main.async {
                    guard let message = self.dataStore.createOwnerVideoMessageWith(assetID: assetID,
                                                                                   videoDuration: duration,
                                                                                   previewData: previewData,
                                                                                   inChat: chat) else {
                        let error = NSError(domain: "Cannot create message", code: 666)
                        completion?(nil, error)
                        return
                    }
                    self.setUnsentStatusTo(chat: chat)

                    self.input.uploadData(videoData, withFileExtension: "mp4") { videoURL, videoUploadError in
                        guard videoUploadError == nil else { completion?(nil, videoUploadError); return }
                        guard let urlString = videoURL else {
                            let noURLError = NSError(domain: "Response does not contain URL", code: 666)
                            completion?(nil, noURLError)
                            return
                        }
                        message.file.url = urlString
                        message.file.isDownloaded = true
                        if let previewData = previewData {
                            self.input.uploadData(previewData, withFileExtension: "jpg") { previewURLString, _ in
                                message.file.prev_url = previewURLString
                                sendMessage(message)
                            }
                        } else {
                            sendMessage(message)
                        }
                    }
                }
            }
        }
    }

    public func sendLocationMessageTo(chat: Dialog,
                                      withLocation location: CLLocation,
                                      description: String?,
                                      image: UIKit.UIImage?,
                                      completion: MessageManagerCompletion?) {
        let previewData: Data?
        if let preview = image {
            let mediaEditor = MediaEditor()
            previewData = mediaEditor.previewImageWith(preview, imageSideLength: 400)
        } else {
            previewData = nil
        }

        var locationData: [String: Any] = ["lat": location.coordinate.latitude, "lon": location.coordinate.longitude]
        if let description = description { locationData["textMsg"] = description }

        guard let message = self.dataStore.createOwnerLocationMessageWith(locationData: locationData,
                                                                          inChat: chat) else {
            let error = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, error)
            return
        }

        self.setUnsentStatusTo(chat: chat)

        self.input.sendLocationMessage(message, toChat: chat) { sendingResult, error in
            guard error == nil else { completion?(message, error); return }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot send message", code: 666)
                completion?(message, error)
                return
            }
            _ = self.updateMessage(message, chat: chat, withSendingResult: sendingResult)
            completion?(message, error)
        }
    }

    fileprivate func validateChat(_ chat: Dialog) -> (Bool, Error?) {
        guard chat.chatID != nil else {
            let chatIDError = NSError(domain: "Cannot send message to chat without ID", code: 666)
            return (false, chatIDError)
        }
        return (true, nil)
    }

    fileprivate func updateMessage(_ message: Message,
                                   chat: Dialog,
                                   withSendingResult sendingResult: MessageSendingResult) -> Message {
        if let lastMessageInChat = chat.lastMessage, lastMessageInChat == message {
            chat.lastMessageStatus = sendingResult.messageStatus
        }
        message.deliver = stringFromMessageStatus(sendingResult.messageStatus)
        if message.linkID == nil || (message.linkID != nil && message.linkID.isEmpty) {
            message.linkID = sendingResult.packetID
        }
        let messageID = chat.chatID! + "<<" + message.linkID!
        CoreDataFacade.sharedInstance().setNewPacketID(sendingResult.packetID,
                                                       moID: messageID,
                                                       andCreationTime: sendingResult.creationTime,
                                                       for: message)
        SenderCore.shared().interfaceUpdater.messagesWereUpdated([message])
        return message
    }

    fileprivate func updateMessage(_ message: Message,
                                   chat: Dialog,
                                   withEditSendingResult sendingResult: MessageSendingResult) -> Message {
        CoreDataFacade.sharedInstance().setNewPacketID(sendingResult.packetID,
                                                       moID: nil,
                                                       andCreationTime: nil,
                                                       for: message)
        SenderCore.shared().interfaceUpdater.messagesWereUpdated([message])
        return message
    }

    public func editTextMessage(_ textMessage: Message, withText text: String, completion: MessageManagerCompletion?) {
        let oldMessageData = textMessage.data
        let oldEncryptionEnabled = textMessage.encrypted?.boolValue ?? false
        let encryptionEnabled = oldEncryptionEnabled
        let (editedMessage, settingTextError) = self.setText(text,
                                                             toMessage: textMessage,
                                                             inChat: textMessage.dialog,
                                                             encryptionEnabled: encryptionEnabled)

        func resetMessageText(message: Message) -> Message {
            message.data = oldMessageData
            message.encrypted = NSNumber(value: oldEncryptionEnabled)
            return message
        }

        self.input.sendTextMessage(editedMessage, toChat: editedMessage.dialog) { sendingResult, error in
            guard error == nil else {
                let resetMessage = resetMessageText(message: editedMessage)
                completion?(resetMessage, error)
                return
            }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot edit message", code: 666)
                let resetMessage = resetMessageText(message: editedMessage)
                completion?(resetMessage, error)
                return
            }
            _ = self.updateMessage(editedMessage, chat: editedMessage.dialog, withEditSendingResult: sendingResult)
            SenderCore.shared().interfaceUpdater.messagesWereUpdated([editedMessage])
            completion?(editedMessage, error)
        }
    }

    public func deleteTextMessage(_ textMessage: Message, completion: MessageManagerCompletion?) {
        let oldMessageData = textMessage.data
        let oldEncryptionEnabled = textMessage.encrypted?.boolValue ?? false
        let editedMessage = self.deleteTextOf(message: textMessage)

        func resetMessageText(message: Message) -> Message {
            message.data = oldMessageData
            message.encrypted = NSNumber(value: oldEncryptionEnabled)
            return message
        }

        self.input.sendTextMessage(editedMessage, toChat: editedMessage.dialog) { sendingResult, error in
            guard error == nil else {
                let resetMessage = resetMessageText(message: editedMessage)
                completion?(resetMessage, error)
                return
            }
            guard let sendingResult = sendingResult else {
                let error = NSError(domain: "Cannot delete message", code: 666)
                let resetMessage = resetMessageText(message: editedMessage)
                completion?(resetMessage, error)
                return
            }
            _ = self.updateMessage(editedMessage, chat: editedMessage.dialog, withEditSendingResult: sendingResult)
            SenderCore.shared().interfaceUpdater.messagesWereUpdated([editedMessage])
            completion?(editedMessage, error)
        }
    }
}
