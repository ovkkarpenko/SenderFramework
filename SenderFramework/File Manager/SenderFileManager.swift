//
// Created by Roman Serga on 13/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

@objc(MWSenderFileManager)
public class SenderFileManager: NSObject {
    @objc public static let shared = SenderFileManager()

    @objc public var lastRecorderAudioDuration: String?

    @objc public var cachesDirectory: URL? {
        guard var cachesDirectory = try? FileManager.default.url(for: .cachesDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: true) else { return  nil }
        cachesDirectory.appendPathComponent("AudioFiles")
        try? FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: true)
        return cachesDirectory
    }

    @objc public var tmpDirectory: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

    @objc public func saveData(_ data: Data, withRemoteURL remoteURL: URL, completion: ((URL?, Error?) -> Void)?) {
        DispatchQueue.global().async {
            guard let cachesDirectory = self.cachesDirectory else {
                let error = NSError(domain: "Cannot get documents directory", code: 1)
                completion?(nil, error)
                return
            }
            let fileName = ProcessInfo.processInfo.globallyUniqueString
            let fileExtension = remoteURL.pathExtension
            let fileURL = cachesDirectory.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
            do {
                try data.write(to: fileURL, options: .atomic)
                completion?(fileURL, nil)
            } catch let writeError as NSError {
                completion?(nil, writeError)
            }
        }
    }

    @objc public func saveImageDataToPhotosAlbum(_ imageData: Data, completion: ((String?, Error?) -> Void)?) {
        guard let image = UIImage(data: imageData) else {
            let wrongDataError = NSError(domain: "Wrong image data", code: 1)
            completion?(nil, wrongDataError)
            return
        }
        let albumName = "SENDER"

        var assetPlaceholder: PHObjectPlaceholder?
        self.getAlbumWith(title: albumName) { album, error in
            guard error == nil else { completion?(nil, error); return }

            guard let album = album else {
                let albumError = NSError(domain: "Cannot get album", code: 1)
                completion?(nil, albumError)
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                assetPlaceholder = assetRequest.placeholderForCreatedAsset
                if let placeholder = assetPlaceholder {
                    let placeholders = [placeholder] as NSArray
                    albumChangeRequest?.addAssets(placeholders)
                }
            }) { success, saveError in
                guard saveError == nil else { completion?(nil, saveError); return }
                guard success,
                      let assetID = assetPlaceholder?.localIdentifier,
                      let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID],
                                                      options: nil).firstObject as? PHAsset else {
                    let assetError = NSError(domain: "Cannot create asset", code: 1)
                    completion?(nil, assetError)
                    return
                }
                completion?(assetID, nil)
            }
        }
    }

    @objc public func saveVideoDataToPhotosAlbum(_ videoData: Data, completion: ((String?, Error?) -> Void)?) {
        let albumName = "SENDER"
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        let fileURL = self.tmpDirectory.appendingPathComponent(fileName).appendingPathExtension("mp4")
        do {
            func clearTempData() { try? FileManager.default.removeItem(at: fileURL) }
            try videoData.write(to: fileURL, options: .atomic)

            var assetPlaceholder: PHObjectPlaceholder?
            self.getAlbumWith(title: albumName) { album, error in
                guard error == nil else {
                    clearTempData()
                    completion?(nil, error)
                    return
                }

                guard let album = album else {
                    let albumError = NSError(domain: "Cannot get album", code: 1)
                    clearTempData()
                    completion?(nil, albumError)
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                    assetPlaceholder = assetRequest?.placeholderForCreatedAsset
                    if let placeholder = assetPlaceholder {
                        let placeholders = [placeholder] as NSArray
                        albumChangeRequest?.addAssets(placeholders)
                    }
                }) { success, saveError in
                    clearTempData()
                    guard saveError == nil else { completion?(nil, saveError); return }
                    guard success,
                          let assetID = assetPlaceholder?.localIdentifier,
                          let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID],
                                                          options: nil).firstObject as? PHAsset else {
                        let assetError = NSError(domain: "Cannot create asset", code: 1)
                        completion?(nil, assetError)
                        return
                    }
                    completion?(assetID, nil)
                }
            }

        } catch let writeError as NSError {
            completion?(nil, writeError)
        }
    }

    private func getAlbumWith(title: String, completion: ((PHAssetCollection?, Error?) -> Void)?) {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        if let album = collection.firstObject as? PHAssetCollection {
            completion?(album, nil)
            return
        }

        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        }) { (success, error) -> Void in
            guard error == nil else { completion?(nil, error); return }
            guard success,
                  let albumID = placeholder?.localIdentifier,
                  let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID],
                                                                      options: nil).firstObject as? PHAssetCollection else {
                let albumError = NSError(domain: "Cannot create album with title: \(title)", code: 1)
                completion?(nil, albumError)
                return
            }
            completion?(album, nil)
        }
    }

    @objc public func imageFromPhotosAlbumWith(assetID: String, completion: ((UIImage?, Error?) -> Void)?) {
        let options = PHFetchOptions()
        options.fetchLimit = 1
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID],
                                              options: options).firstObject as? PHAsset else {
            let error = NSError(domain: "Cannot fetch asset", code: 1)
            completion?(nil, error)
            return
        }

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: PHImageManagerMaximumSize,
                                              contentMode: .aspectFill,
                                              options: nil) { image, info in
            guard !(info?[PHImageResultIsDegradedKey] as? Bool ?? false) else { return }
            completion?(image, nil)
        }
    }

    @objc public func videoFromPhotosAlbumWith(assetID: String, completion: ((Data?, URL?, Error?) -> Void)?) {
        let options = PHFetchOptions()
        options.fetchLimit = 1
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID],
                                              options: options).firstObject as? PHAsset else {
            let error = NSError(domain: "Cannot fetch asset", code: 1)
            completion?(nil, nil, error)
            return
        }

        PHImageManager.default().requestPlayerItem(forVideo: asset,
                                                   options: nil) { playItem, _ in
            guard let playItem = playItem, let urlAsset = playItem.asset as? AVURLAsset else {
                let error = NSError(domain: "Cannot get asset", code: 1)
                completion?(nil, nil, error)
                return
            }
            do {
                let videoData = try Data(contentsOf: urlAsset.url)
                completion?(videoData, urlAsset.url, nil)
            } catch let dataError as NSError {
                completion?(nil, nil, dataError)
            }
        }
    }
}
