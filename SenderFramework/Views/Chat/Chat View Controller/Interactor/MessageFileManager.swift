//
// Created by Roman Serga on 7/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class MessageFileManager {
    let fileStore: MessageFileStore

    init(fileStore: MessageFileStore) {
        self.fileStore = fileStore
    }

    func loadImageFor(message: Message, completion: @escaping ((UIImage?, Error?) -> Void)) {
        if let assetID = message.file?.localUrl {
            self.fileStore.getImageWith(assetID: assetID) { image, error in
                DispatchQueue.main.async {
                    guard image != nil else {
                        message.file.localUrl = nil
                        self.loadImageFor(message: message, completion: completion)
                        return
                    }
                    completion(image, error)
                }
            }
        } else if let remoteURLString = message.file.url {
            self.fileStore.getImageWith(remoteURLString: remoteURLString) { image, assetID, error in
                DispatchQueue.main.async {
                    /*
                        If we started loading image by remote url, message's local URL is invalid.
                        That's why we should replace current local URL of message even if the returned one is nil.
                        If we don't replace it, next time we will again try to get an image with wrong local URL.
                    */
                    message.file.localUrl = assetID

                    guard error == nil else {
                        completion(image, error); return
                    }
                    guard image != nil, assetID != nil else {
                        let getImageError = NSError(domain: "Cannot get image", code: 666)
                        completion(image, getImageError)
                        return
                    }

                    completion(image, error)
                }
            }
        } else {
            let urlError = NSError(domain: "Message has invalid URLs", code: 666)
            completion(nil, urlError)
        }
    }

    func loadVideoFor(message: Message, completion: @escaping ((URL?, Error?) -> Void)) {
        if let assetID = message.file?.localUrl {
            self.fileStore.getVideoWith(assetID: assetID) { videoData, videoURL, error in
                DispatchQueue.main.async {
                    guard videoData != nil else {
                        message.file.localUrl = nil
                        self.loadVideoFor(message: message, completion: completion)
                        return
                    }
                    completion(videoURL, error)
                }
            }
        } else if let remoteURLString = message.file.url {
            self.fileStore.getVideoWith(remoteURLString: remoteURLString) { videoData, assetID, videoURL, error in
                DispatchQueue.main.async {
                    /*
                        If we started loading video by remote url, message's local URL is invalid.
                        That's why we should replace current local URL of message even if the returned one is nil.
                        If we don't replace it, next time we will again try to get an video with wrong local URL.
                    */
                    message.file.localUrl = assetID

                    guard error == nil else {
                        completion(videoURL, error); return
                    }
                    guard videoData != nil, videoURL != nil else {
                        let getVideoError = NSError(domain: "Cannot get video", code: 666)
                        completion(videoURL, getVideoError)
                        return
                    }

                    completion(videoURL, error)
                }
            }
        } else {
            let urlError = NSError(domain: "Message has invalid URLs", code: 666)
            completion(nil, urlError)
        }
    }

    func loadAudioFor(message: Message, completion: @escaping ((URL?, Error?) -> Void)) {
        if let localURLString = message.file?.localUrl, let localURL = URL(string: localURLString) {
            self.fileStore.getFileWith(localURL: localURL) { audioData, error in
                DispatchQueue.main.async {
                    guard audioData != nil else {
                        message.file.localUrl = nil
                        self.loadAudioFor(message: message, completion: completion)
                        return
                    }
                    completion(localURL, error)
                }
            }
        } else if let remoteURLString = message.file.url {
            self.fileStore.getFileWith(remoteURLString: remoteURLString) { audioData, localURL, error in
                DispatchQueue.main.async {
                    /*
                        If we started loading audio by remote url, message's local URL is invalid.
                        That's why we should replace current local URL of message even if the returned one is nil.
                        If we don't replace it, next time we will again try to get an audio with wrong local URL.
                    */
                    message.file.localUrl = localURL?.absoluteString

                    guard error == nil else {
                        completion(localURL, error); return
                    }
                    guard audioData != nil, localURL != nil else {
                        let getAudioError = NSError(domain: "Cannot get audio", code: 666)
                        completion(localURL, getAudioError)
                        return
                    }

                    completion(localURL, error)
                }
            }
        } else {
            let urlError = NSError(domain: "Message has invalid URLs", code: 666)
            completion(nil, urlError)
        }
    }

    func loadFileFor(message: Message, completion: @escaping ((URL?, Error?) -> Void)) {
        if let localURLString = message.file?.localUrl, let localURL = URL(string: localURLString) {
            self.fileStore.getFileWith(localURL: localURL) { fileData, error in
                DispatchQueue.main.async {
                    guard fileData != nil else {
                        message.file.localUrl = nil
                        self.loadFileFor(message: message, completion: completion)
                        return
                    }
                    completion(localURL, error)
                }
            }
        } else if let remoteURLString = message.file.url {
            self.fileStore.getFileWith(remoteURLString: remoteURLString) { fileData, localURL, error in
                DispatchQueue.main.async {
                    /*
                        If we started loading file by remote url, message's local URL is invalid.
                        That's why we should replace current local URL of message even if the returned one is nil.
                        If we don't replace it, next time we will again try to get an file with wrong local URL.
                    */
                    message.file.localUrl = localURL?.absoluteString

                    guard error == nil else {
                        completion(localURL, error); return
                    }
                    guard fileData != nil, localURL != nil else {
                        let getFileError = NSError(domain: "Cannot get file", code: 666)
                        completion(localURL, getFileError)
                        return
                    }

                    completion(localURL, error)
                }
            }
        } else {
            let urlError = NSError(domain: "Message has invalid URLs", code: 666)
            completion(nil, urlError)
        }
    }
}
