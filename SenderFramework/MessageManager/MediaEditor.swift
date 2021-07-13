//
// Created by Roman Serga on 28/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class MediaEditor {

    func dataRepresentationOf(image: UIImage) -> Data? {
        return UIImageJPEGRepresentation(image, 1.0)
    }

    func compressedImage(_ image: UIImage,
                         withScaleRatio scaleRatio: CGFloat,
                         compressionQuality: CGFloat) -> (CGSize, Data)? {
        let scaledSize = CGSize(width: image.size.width / scaleRatio, height: image.size.height / scaleRatio)
        guard let scaledImage = self.scaledImage(image: image, toSize: scaledSize) else { return nil }
        let compressedData = UIImageJPEGRepresentation(scaledImage, compressionQuality)
        return compressedData != nil ? (scaledSize, compressedData!) : nil
    }

    func scaledImage(image: UIImage, toSize size: CGSize) -> UIImage? {
        let clipRect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: clipRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    func previewImageWith(_ image: UIImage, imageSideLength: CGFloat) -> Data? {
        guard image.size.height > imageSideLength && image.size.width > imageSideLength else {
            return UIImagePNGRepresentation(image)
        }
        let size = image.size
        let ratio = size.height < size.width ? size.height / imageSideLength : size.width / imageSideLength
        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        defer {
            UIGraphicsEndImageContext()
        }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        if newSize.height < newSize.width {
            x = (newSize.width - newSize.height) / 2.0
        } else if newSize.height > newSize.width {
            y = (newSize.height - newSize.width) / 2.0
        }
        let clipRect = CGRect(x: x, y: y, width: imageSideLength, height: imageSideLength)
        guard let imageRef = newImage.cgImage?.cropping(to: clipRect) else { return nil }
        let clippedImage = UIImage(cgImage: imageRef)
        return UIImagePNGRepresentation(clippedImage)
    }

    func previewImageWith(videoURL: URL, imageSideLength: CGFloat, completion: ((Data?, Error?) -> Void)?) {
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let maxSize = CGSize(width: imageSideLength, height: imageSideLength)
        let thumbTime = NSValue(time: CMTimeMakeWithSeconds(0, 30))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maxSize
        generator.generateCGImagesAsynchronously(forTimes: [thumbTime]) { _, image, _, _, error in
            guard error == nil else { completion?(nil, error); return }
            guard let image = image else {
                let error = NSError(domain: "Cannot get thumbnail", code: 666)
                completion?(nil, error)
                return
            }
            let thumbnail = UIImage(cgImage: image)
            let compressedThumbnail = self.previewImageWith(thumbnail, imageSideLength: imageSideLength)
            guard let compressedThumbnailUnwrapped = compressedThumbnail else {
                let thumbnailError = NSError(domain: "Cannot get thumbnail", code: 666)
                completion?(nil, thumbnailError)
                return
            }
            completion?(compressedThumbnailUnwrapped, nil)
        }
    }
}
