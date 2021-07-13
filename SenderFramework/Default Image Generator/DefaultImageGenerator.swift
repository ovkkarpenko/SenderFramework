//
// Created by Roman Serga on 11/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

/*
    Checking emoji availability from https://stackoverflow.com/a/41393387/6415245
 */
fileprivate func isEmojiAvailable(_ emojiCode: Character) -> Bool {
    let refCode = Character("\u{1f3f6}") // do not change this

    if let refData = characterData(refCode),
       let testData = characterData(emojiCode) {
        return !(refData as NSData).isEqual(to: testData)
    }
    return false
}

fileprivate func characterData(_ char: Character) -> Data? {
    let charStr = "\(char)" as NSString
    let size = charStr.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])

    UIGraphicsBeginImageContext(size)
    charStr.draw(at: CGPoint(x: 0, y :0), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])

    var charData: Data? = nil
    if let charImage = UIGraphicsGetImageFromCurrentImageContext() {
        charData = UIImagePNGRepresentation(charImage)
    }

    UIGraphicsEndImageContext()
    return charData
}

@objc(MWRandomEmojiGenerator)
public class RandomEmojiGenerator: NSObject {
    static let availableEmoji: [String] = ["😀", "😜", "😎", "😇", "🤠", "🤡",
                                           "👻", "👽", "🤖", "😺", "🐵", "🐶",
                                           "🦊", "🐱", "🦁", "🐯", "🐭", "🐹",
                                           "🐻", "🐨", "🐼", "🍞", "🍿", "🍪",
                                           "👾", "🎲", "🥁", "🎱", "🎾", "🏈",
                                           "🏀", "⚽", "🎁"].filter({ isEmojiAvailable($0) }).map({String($0)})

    @objc public static func generateRandomEmoji() -> String {
        let index = Int(arc4random_uniform(UInt32(self.availableEmoji.count)))
        return self.availableEmoji[index]
    }
}

@objc(MWDefaultImageGenerator)
public class DefaultImageGenerator: NSObject {
    private static let cache = NSCache<NSString, UIImage>()

    @objc static public func generateDefaultImageWith(emoji: String,
                                                      size: CGSize,
                                                      rounded: Bool,
                                                      backgroundImageName: String? = nil) -> UIImage? {
        if let cachedImage = self.cachedImageFor(emoji: emoji,
                                                 size: size,
                                                 rounded: rounded,
                                                 backgroundImageName: backgroundImageName) {
            return cachedImage
        }
        let maxEmojiHeight = size.height * 0.7
        guard var font = UIFont(name: "AppleColorEmoji", size: 0.0) else { return nil }
        for fontSize in stride(from: 0.0, to: CGFloat.greatestFiniteMagnitude, by: 1.0) {
            guard let newFont = UIFont(name: "AppleColorEmoji", size: fontSize),
                  newFont.lineHeight < maxEmojiHeight else { break }
            font = newFont
        }
        let maxEmojiWidth = size.width * 0.7
        let maxEmojiSize = CGSize(width: maxEmojiWidth, height: maxEmojiHeight)
        let attributedEmoji = NSAttributedString(string: emoji, attributes: [.font: font])
        let emojiSize = attributedEmoji.boundingRect(with: maxEmojiSize, options: [], context: nil)
        let emojiRect = CGRect(x: (size.width - emojiSize.width) / 2,
                               y: (size.height - emojiSize.height) / 2,
                               width: emojiSize.width,
                               height: emojiSize.height)
        let backgroundImage: UIImage?
        if let backgroundImageName = backgroundImageName {
            backgroundImage = UIImage(fromSenderFrameworkNamed: backgroundImageName)
        } else {
            backgroundImage = nil
        }
        let defaultImage = self.drawText(emoji,
                                         withFont: font,
                                         inRect: emojiRect,
                                         background: backgroundImage,
                                         size: size,
                                         rounded: rounded)
        if let defaultImageUnwrapped = defaultImage {
            self.addImageToCache(defaultImageUnwrapped,
                                 forEmoji: emoji,
                                 size: size,
                                 rounded: rounded,
                                 backgroundImageName: backgroundImageName)
        }
        return defaultImage
    }

    private static func drawText(_ text: String,
                                 withFont font: UIFont,
                                 inRect rect: CGRect,
                                 background: UIImage?,
                                 size: CGSize,
                                 rounded: Bool) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        let imageRect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        if rounded {
            let path = UIBezierPath.init(roundedRect: imageRect, cornerRadius: rect.height)
            UIGraphicsGetCurrentContext()?.addPath(path.cgPath)
            UIGraphicsGetCurrentContext()?.clip()
        }
        UIColor.white.setFill()
        UIGraphicsGetCurrentContext()?.fill(imageRect)
        if let background = background { background.draw(in: imageRect) }
        (text as NSString).draw(in: rect, withAttributes: [.font: font])
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage
    }

    static func keyFor(emoji: String,
                       size: CGSize,
                       rounded: Bool,
                       backgroundImageName: String?) -> String {
        let sizeDescription = NSStringFromCGSize(size)
        let roundedDescription = rounded ? "r" : "nr"
        let backgroundImageDescription = backgroundImageName ?? ""
        return "\(emoji)_\(sizeDescription)_\(roundedDescription)_\(backgroundImageDescription)"
    }

    static func addImageToCache(_ image: UIImage,
                                forEmoji emoji: String,
                                size: CGSize,
                                rounded: Bool,
                                backgroundImageName: String?) {
        let key = self.keyFor(emoji: emoji, size: size, rounded: rounded, backgroundImageName: backgroundImageName)
        self.cache.setObject(image, forKey: (key as NSString))
    }

    static func cachedImageFor(emoji: String,
                               size: CGSize,
                               rounded: Bool,
                               backgroundImageName: String?) -> UIImage? {
        let key = self.keyFor(emoji: emoji, size: size, rounded: rounded, backgroundImageName: backgroundImageName)
        return self.cache.object(forKey: (key as NSString))
    }
}
