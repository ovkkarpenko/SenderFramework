//
// Created by Roman Serga on 7/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import AssetsLibrary

class MessageFileStore {
    func getImageWith(assetID: String, completion: @escaping ((UIImage?, Error?) -> Void)) {
        SenderFileManager.shared.imageFromPhotosAlbumWith(assetID: assetID, completion: completion)
    }

    func getImageWith(remoteURLString: String, completion: @escaping ((UIImage?, String?, Error?) -> Void)) {
        ServerFacade.sharedInstance().downloadFile(forURLSting: remoteURLString) { data, error in
            guard error == nil else { completion(nil, nil, error); return }
            guard let data = data else {
                let downloadError = NSError(domain: "Cannot download image", code: 1)
                completion(nil, nil, downloadError)
                return
            }

            SenderFileManager.shared.saveImageDataToPhotosAlbum(data) { assetID, error in
                guard error == nil else { completion(nil, nil, error); return }
                guard let assetID = assetID else {
                    let error = NSError(domain: "Cannot get saved assetID", code: 666)
                    completion(nil, nil, error)
                    return
                }
                self.getImageWith(assetID: assetID) { image, error in completion(image, assetID, error) }
            }
        }
    }

    func getVideoWith(assetID: String, completion: @escaping ((Data?, URL?, Error?) -> Void)) {
        SenderFileManager.shared.videoFromPhotosAlbumWith(assetID: assetID, completion: completion)
    }

    func getVideoWith(remoteURLString: String, completion: @escaping ((Data?, String?, URL?, Error?) -> Void)) {
        guard let url = NSURL.mw_URLByAddingPercentEscapes(to: remoteURLString) as URL? else {
            let error = NSError(domain: "Wrong video URL", code: 666)
            completion(nil, nil, nil, error)
            return
        }
        DispatchQueue.global(qos: .utility).async {
            do {
                let videoData = try Data(contentsOf: url, options: .uncached)
                SenderFileManager.shared.saveVideoDataToPhotosAlbum(videoData) { assetID, error in
                    guard error == nil else {
                        completion(nil, nil, nil, error); return
                    }
                    guard let assetID = assetID else {
                        let error = NSError(domain: "Cannot get saved assetID", code: 666)
                        completion(nil, nil, nil, error)
                        return
                    }
                    self.getVideoWith(assetID: assetID) { videoData, videoURL, error in
                        completion(videoData, assetID, videoURL, error)
                    }
                }
            } catch let error as NSError {
                completion(nil, nil, nil, error)
                return
            }
        }
    }

    func getFileWith(localURL: URL, completion: @escaping ((Data?, Error?) -> Void)) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let fileData = try Data(contentsOf: localURL, options: .uncached)
                completion(fileData, nil)
            } catch let error as NSError {
                completion(nil, error)
                return
            }
        }
    }

    func getFileWith(remoteURLString: String, completion: @escaping ((Data?, URL?, Error?) -> Void)) {
        guard let url =  NSURL.mw_URLByAddingPercentEscapes(to: remoteURLString) as URL? else {
            let error = NSError(domain: "Wrong file URL", code: 666)
            completion(nil, nil, error)
            return
        }
        DispatchQueue.global(qos: .utility).async {
            do {
                let fileData = try Data(contentsOf: url, options: .uncached)
                SenderFileManager.shared.saveData(fileData, withRemoteURL: url) { fileURL, error in
                    guard error == nil else { completion(nil, nil, error); return }
                    guard let fileURL = fileURL else {
                        let error = NSError(domain: "Cannot get saved fileURL", code: 666)
                        completion(nil, nil, error)
                        return
                    }
                    self.getFileWith(localURL: fileURL) { fileData, error in
                        completion(fileData, fileURL, error)
                    }
                }
            } catch let error as NSError {
                completion(nil, nil, error)
                return
            }
        }
    }
}
