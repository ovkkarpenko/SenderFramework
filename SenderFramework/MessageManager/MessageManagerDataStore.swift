//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import AssetsLibrary

@objc(MWMessageManagerDataStore)
public class MessageManagerDataStore: NSObject, MessageManagerDataStoreProtocol {
    public func createOwnerTextMessageWith(text: String, inChat chat: Dialog) -> Message? {
        return CoreDataFacade.sharedInstance().writeMessage(withText: text, inChat: chat)
    }

    public func createOwnerStickerMessageWith(stickerID: String, inChat chat: Dialog) -> Message? {
        return CoreDataFacade.sharedInstance().writeMessage(withStickerID: stickerID, inChat: chat)
    }

    public func createOwnerAudioMessageWith(audioData: Data, inChat chat: Dialog) -> Message? {
        return CoreDataFacade.sharedInstance().writeVoiceMessage(inChat: chat)
    }

    public func createOwnerVibroMessageIn(chat: Dialog) -> Message? {
        return CoreDataFacade.sharedInstance().writeVibroMessage(inChat: chat)
    }

    public func createOwnerImageMessageWith(imageData: Data,
                                            assetID: String,
                                            previewData: Data?,
                                            inChat chat: Dialog,
                                            completion: ((Message?, Error?) -> Void)?) {
        guard let message = CoreDataFacade.sharedInstance().writeImageMessage(withLocalURL:assetID,
                                                                              inChat:chat) else {
            let messageError = NSError(domain: "Cannot create message", code: 666)
            completion?(nil, messageError)
            return
        }
        message.file.url = assetID
        message.file.localUrl = assetID
        message.file.isDownloaded = true
        completion?(message, nil)
    }

    public func createOwnerVideoMessageWith(assetID: String,
                                            videoDuration: TimeInterval,
                                            previewData: Data?,
                                            inChat chat: Dialog) -> Message? {
        guard let message = CoreDataFacade.sharedInstance().writeVideoMessage(withLocalURL: assetID,
                                                                              videoDuration: videoDuration,
                                                                              inChat: chat) else { return nil }
        message.file.url = assetID
        message.file.localUrl = assetID
        message.file.isDownloaded = true
        return message
    }

    public func createOwnerLocationMessageWith(locationData: [AnyHashable: Any], inChat chat: Dialog) -> Message? {
        return CoreDataFacade.sharedInstance().writeLocationMessage(withData: locationData, inChat: chat)
    }

    public func saveImageToPhotoAlbum(imageData: Data, completion: ((String?, Error?) -> Void)?) {
        SenderFileManager.shared.saveImageDataToPhotosAlbum(imageData, completion: completion)
    }

    public func saveVideoToPhotoAlbum(videoData: Data, completion: ((String?, Error?) -> Void)?) {
        SenderFileManager.shared.saveVideoDataToPhotosAlbum(videoData, completion: completion)
    }

    public func imageWith(assetID: String, completion: ((UIKit.UIImage?, Error?) -> Void)?) {
        SenderFileManager.shared.imageFromPhotosAlbumWith(assetID: assetID, completion: completion)
    }

    public func videoDataWith(assetID: String, completion: ((Data?, URL?, Error?) -> Void)?) {
        SenderFileManager.shared.videoFromPhotosAlbumWith(assetID: assetID, completion: completion)
    }
}
