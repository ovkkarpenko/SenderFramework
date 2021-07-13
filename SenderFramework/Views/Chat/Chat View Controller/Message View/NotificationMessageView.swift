//
// Created by Roman Serga on 17/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class NotificationMessageViewLayout: BaseMessageLayout {}

class NotificationMessageView: MessageView {
    static let regularTextViewFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    static let verticalTextViewOffset: CGFloat = 3.0
    static let horizontalTextViewOffset: CGFloat = 10.0
    static let textViewLineBreakingMode: NSLineBreakMode = .byTruncatingTail
    class var maximumNumberOfLines: Int { return 2 }

    let textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.textContainerInset = .zero
        textView.dataDetectorTypes = []
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .center
        return textView
    }()

    override func setUp() {
        super.setUp()
        self.backgroundColor = SenderCore.shared().stylePalette.chatNotificationBackgroundColor
        self.textView.backgroundColor = .clear
        self.textView.font = type(of: self).regularTextViewFont
        self.textView.textColor = SenderCore.shared().stylePalette.chatNotificationTextColor
        textView.textContainer.maximumNumberOfLines = type(of: self).maximumNumberOfLines
        textView.textContainer.lineBreakMode = type(of: self).textViewLineBreakingMode
        self.addSubview(textView)
    }

    static func sizeWith(text: String, maxWidth: CGFloat, font: UIFont) -> CGSize {
        let maxWidthWithOffsets = maxWidth - 2 * self.horizontalTextViewOffset
        let textContainer: NSTextContainer = {
            let size = CGSize(width: maxWidthWithOffsets, height: .greatestFiniteMagnitude)
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = self.maximumNumberOfLines
            container.lineBreakMode = self.textViewLineBreakingMode
            return container
        }()

        let textStorage = NSTextStorage(string: text,
                                        attributes: [.font: font,
                                                     NSAttributedStringKey(rawValue: "NSOriginalFont"): font])

        let layoutManager: NSLayoutManager = {
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            return layoutManager
        }()

        let rect = layoutManager.usedRect(for: textContainer)
        let size = CGSize(width: CGFloat(ceilf(Float(rect.width))) + 2 * self.horizontalTextViewOffset,
                          height: CGFloat(ceilf(Float(rect.height))) + 2 * self.verticalTextViewOffset)
        return size
    }

    static func layoutWith(text: String, maxWidth: CGFloat) -> NotificationMessageViewLayout {
        let font = self.regularTextViewFont
        let size = self.sizeWith(text: text, maxWidth: maxWidth, font: font)
        return NotificationMessageViewLayout(size: size)
    }

    func updateWith(text: String,
                    maxWidth: CGFloat,
                    layout: NotificationMessageViewLayout? = nil) -> NotificationMessageViewLayout {
        let layout = layout ?? type(of: self).layoutWith(text: text, maxWidth: maxWidth)
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.textView.text = text
        self.setNeedsLayout()
        return layout
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let textViewWidth = self.frame.width - 2 * type(of: self).horizontalTextViewOffset
        let textViewHeight = self.frame.height - 2 * type(of: self).verticalTextViewOffset
        self.textView.frame = CGRect(x: type(of: self).horizontalTextViewOffset,
                                     y: type(of: self).verticalTextViewOffset,
                                     width: textViewWidth,
                                     height: textViewHeight)
        self.layer.cornerRadius = self.frame.height / 2
    }
}
