//
// Created by Roman Serga on 6/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class TextMessageViewLayout: MessageWithTimeLayout { }

class TextMessageView: MessageView {
    static let regularTextViewFont: UIFont = SenderCore.shared().stylePalette.inputTextFieldFontStyle(nil, andSize: 16)
    static let emojiTextViewFont: UIFont? = UIFont(name: "AppleColorEmoji", size: 37)
    static let textViewTextColor: UIColor = SenderCore.shared().stylePalette.mainTextColor

    static let timeLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0)

    static let textVerticalOffset: CGFloat = 7.0
    static let textHorizontalOffset: CGFloat = 12.0
    static let defaultCornerRadius: CGFloat = 17.0

    static let timeLabelToTextTrailing: CGFloat = 8.0
    static let messageStatusWidth: CGFloat = 24.0

    static let minimalHeight: CGFloat = 32.0

    var showMessageStatus: Bool = false

    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        timeLabel.textAlignment = .right
        return timeLabel
    }()

    let textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.textContainerInset = .zero
        textView.dataDetectorTypes = .all
        textView.textContainer.lineFragmentPadding = 0.0
        return textView
    }()

    override func setUp() {
        super.setUp()
        self.setNewBackgroundColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 204.0/255.0, alpha: 1.0))
        self.textView.font = type(of: self).regularTextViewFont
        self.textView.textColor = type(of: self).textViewTextColor
        timeLabel.font = type(of: self).timeLabelFont
        self.addSubview(self.textView)
        self.addSubview(self.timeLabel)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    static func fontWith(text: String) -> UIFont {
        let emojiFont = emojiTextViewFont ?? regularTextViewFont
        return (text as NSString).isSingleEmoji() ? emojiFont : regularTextViewFont
    }

    static func sizeWith(text: String,
                         maxWidth: CGFloat,
                         textFont: UIFont,
                         timeDescription: String?,
                         isEditedMessage: Bool) -> (CGSize, CGSize) {
        let textContainer: NSTextContainer = {
            let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0.0
            return container
        }()

        let timeLabelText: String
        if let timeDescription = timeDescription {
            timeLabelText = timeDescription + (isEditedMessage ? " ✏️" : "")
        } else {
            timeLabelText = isEditedMessage ? "✏️" : ""
        }
        let attributedTimeLabelText = NSAttributedString(string: timeLabelText, attributes: [.font: self.timeLabelFont])
        let sizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let maxTimeLabelSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var timeLabelSize = attributedTimeLabelText.boundingRect(with: maxTimeLabelSize,
                                                                 options: sizeCalculateOptions,
                                                                 context: nil).mw_rounded().size
        timeLabelSize.width += self.timeLabelToTextTrailing

        let timeAttachment = NSTextAttachment(data: nil, ofType: nil)
        timeAttachment.image = UIImage()
        timeAttachment.bounds = CGRect(origin: .zero, size: timeLabelSize)

        let textStorage = NSTextStorage(string: text,
                                        attributes: [.font: textFont,
                                                     NSAttributedStringKey(rawValue: "NSOriginalFont"): textFont])
        textStorage.append(NSAttributedString(attachment: timeAttachment))

        let layoutManager: NSLayoutManager = {
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            return layoutManager
        }()

        let rect = layoutManager.usedRect(for: textContainer)

        let minHeight = self.minimalHeight
        let minWidth = 2 * self.defaultCornerRadius
        let calculatedWidth = CGFloat(ceilf(Float(rect.maxX))) + textHorizontalOffset * 2
        let width = calculatedWidth >= minWidth ? calculatedWidth : minWidth
        let textHeight = CGFloat(ceilf(Float(rect.maxY)))
        var height = textHeight + textVerticalOffset * 2
        height = height < minHeight ? minHeight : height
        let size = CGSize(width: width, height: height)
        return (size, timeLabelSize)
    }

    static func layoutWith(textMessage: TextMessageViewModel, maxWidth: CGFloat) -> TextMessageViewLayout {
        let font = self.fontWith(text: textMessage.text)
        let maxTextWidth = maxWidth - 2 * self.textHorizontalOffset
        let (viewSize, timeLabelSize) = self.sizeWith(text: textMessage.text,
                                                      maxWidth: maxTextWidth,
                                                      textFont: font,
                                                      timeDescription: textMessage.creationTimeDescription,
                                                      isEditedMessage: textMessage.isEdited)
        return TextMessageViewLayout(size: viewSize, timeIndicatorSize: timeLabelSize)
    }

    func updateWith(textMessage: TextMessageViewModel,
                    maxWidth: CGFloat,
                    layout: TextMessageViewLayout? = nil) -> TextMessageViewLayout {
        let ownerMessageColor: UIColor
        let foreignMessageColor: UIColor
        let ownerBorderColor: UIColor
        let foreignBorderColor: UIColor

        if textMessage.isEncrypted {
            ownerMessageColor = SenderCore.shared().stylePalette.encryptedOwnerMessageBackgroundColor
            foreignMessageColor = SenderCore.shared().stylePalette.encryptedMessageBackgroundColor
            ownerBorderColor = ownerMessageColor
            foreignBorderColor = SenderCore.shared().stylePalette.foreignEncryptedMessageBorderColor
        } else {
            ownerMessageColor = SenderCore.shared().stylePalette.myMessageBackgroundColor
            foreignMessageColor = SenderCore.shared().stylePalette.foreignMessageBackgroundColor
            ownerBorderColor = ownerMessageColor
            foreignBorderColor = SenderCore.shared().stylePalette.foreignMessageBorderColor
        }

        self.setNewBackgroundColor(textMessage.author == .owner ? ownerMessageColor : foreignMessageColor)
        self.layer.borderColor = (textMessage.author == .owner ? ownerBorderColor : foreignBorderColor).cgColor
        self.layer.borderWidth = 1.0
        self.textView.font = type(of: self).fontWith(text: textMessage.text)
        self.textView.text = textMessage.text

        self.showMessageStatus = textMessage.isEdited
        self.timeLabel.text = textMessage.creationTimeDescription

        if textMessage.isEdited {
            self.timeLabel.text = self.timeLabel.text != nil ? self.timeLabel.text! +  " ✏️" :  "✏️"
        }

        let layout = layout ?? type(of: self).layoutWith(textMessage: textMessage, maxWidth: maxWidth)
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeLabel.frame = CGRect(origin: self.timeLabel.frame.origin, size: layout.timeIndicatorSize)
        self.setNeedsLayout()

        let menuItemEdit = UIMenuItem(title: SenderFrameworkLocalizedString("edit"),
                                      action: #selector(self.editMessage))
        let menuItemDelete = UIMenuItem(title: SenderFrameworkLocalizedString("delete_ios"),
                                        action: #selector(self.deleteMessage))
        UIMenuController.shared.menuItems = [menuItemEdit, menuItemDelete]

        return layout
    }

    func setNewBackgroundColor(_ newBackgroundColor: UIColor) {
        self.backgroundColor = newBackgroundColor
        self.textView.backgroundColor = newBackgroundColor
        self.timeLabel.backgroundColor = newBackgroundColor
    }

    @objc func editMessage() {
        self.actionsHandler?.messageView(self, didSelectAction: .edit)
    }

    @objc func deleteMessage() {
        self.actionsHandler?.messageView(self, didSelectAction: .delete)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let actionsHandler = self.actionsHandler else {
            return super.canPerformAction(action, withSender: sender)
        }

        let canPerformAction: Bool
        if action == #selector(self.editMessage) {
            canPerformAction = actionsHandler.messageView(self, canPerformAction: .edit)
        } else if action == #selector(self.deleteMessage) {
            canPerformAction = actionsHandler.messageView(self, canPerformAction: .delete)
        } else {
            canPerformAction = super.canPerformAction(action, withSender: sender)
        }
        return canPerformAction
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let textX = type(of: self).textHorizontalOffset
        let textY = type(of: self).textVerticalOffset
        let textWidth = self.frame.width - 2.0 * type(of: self).textHorizontalOffset
        let textHeight = self.frame.height - 2.0 * type(of: self).textVerticalOffset

        self.textView.frame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)

        var newTimeLabelFrame = self.timeLabel.frame
        let newTimeLabelX = self.textView.frame.maxX - newTimeLabelFrame.width
        newTimeLabelFrame.origin.x = newTimeLabelX
        newTimeLabelFrame.origin.y = self.textView.frame.maxY - newTimeLabelFrame.height
        self.timeLabel.frame = newTimeLabelFrame

        let cornerRadius: CGFloat
        if self.frame.height / 2 < type(of: self).defaultCornerRadius {
            cornerRadius = self.frame.height / 2
        } else {
            cornerRadius = type(of: self).defaultCornerRadius
        }
        self.layer.cornerRadius = cornerRadius
    }
}
