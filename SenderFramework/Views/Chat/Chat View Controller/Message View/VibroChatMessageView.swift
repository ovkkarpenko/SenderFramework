//
// Created by Roman Serga on 29/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class VibroChatMessageViewLayout: MessageWithTimeLayout {}

class VibroChatMessageView: MessageView {
    static let vibroChatImageSide: CGFloat = 29.0
    static let vibroChatImageLeading: CGFloat = 4.0

    static let titleToVibroChatImageLeading: CGFloat = 8.0

    static let timeLabelToTitleLeading: CGFloat = 8.0
    static let timeLabelTrailing: CGFloat = 12.0
    static let timeLabelBottom: CGFloat = 8.0
    static let titleLabelHeight: CGFloat = 20.0

    static let titleLabelFont = SenderCore.shared().stylePalette.inputTextFieldFontStyle(nil, andSize: 16)
    static let titleLabelTextColor: UIColor = SenderCore.shared().stylePalette.mainTextColor

    static let timeLabelFont = UIFont.systemFont(ofSize: 12.0)

    static let maxHeight: CGFloat = 36.0

    let vibroChatImageView: UIImageView = {
        let vibroChatImageView = UIImageView(image: UIImage(fromSenderFrameworkNamed: "icVibro"))
        vibroChatImageView.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        return vibroChatImageView
    }()

    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        timeLabel.font = FileMessageView.timeLabelFont
        timeLabel.textAlignment = .center
        return timeLabel
    }()

    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = VibroChatMessageView.titleLabelFont
        titleLabel.textColor = VibroChatMessageView.titleLabelTextColor
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingMiddle
        return titleLabel
    }()

    override func setUp() {
        super.setUp()
        self.layer.borderWidth = 1.0
        self.addSubview(self.timeLabel)
        self.addSubview(self.titleLabel)
        self.addSubview(self.vibroChatImageView)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    convenience init() {
        let frame = CGRect()
        self.init(frame: frame)
    }

    static func layoutWith(vibroChatMessage: VibroChatMessageViewModel,
                           maxWidth: CGFloat) -> VibroChatMessageViewLayout {
        let elementsWidth = self.vibroChatImageLeading + self.vibroChatImageSide +
                self.titleToVibroChatImageLeading + self.timeLabelToTitleLeading + self.timeLabelTrailing
        let maxTimeWidth = maxWidth - elementsWidth
        let attributedTimeLabelText = NSAttributedString(string: vibroChatMessage.creationTimeDescription ?? "",
                                                         attributes: [.font: self.timeLabelFont])
        let timeSizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let maxTimeLabelSize = CGSize(width: maxTimeWidth, height: self.maxHeight)
        let timeLabelSize = attributedTimeLabelText.boundingRect(with: maxTimeLabelSize,
                                                                 options: timeSizeCalculateOptions,
                                                                 context: nil).mw_rounded().size

        let titleAttributes = [.font: self.titleLabelFont,
                               NSAttributedStringKey(rawValue: "NSOriginalFont"): self.titleLabelFont]
        let titleString = NSAttributedString(string: SenderFrameworkLocalizedString("vibro_chat"),
                                             attributes: titleAttributes)
        let maxFileNameWidth = maxWidth - elementsWidth - timeLabelSize.width
        let maxFileNameSize = CGSize(width: maxFileNameWidth, height: self.maxHeight)
        let sizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let fileNameLabelEstimatedSize = titleString.boundingRect(with: maxFileNameSize,
                                                                  options: sizeCalculateOptions,
                                                                  context: nil).mw_rounded()

        let viewWidth = elementsWidth + timeLabelSize.width + fileNameLabelEstimatedSize.width
        let viewSize = CGSize(width: viewWidth, height: self.maxHeight)
        return VibroChatMessageViewLayout(size: viewSize, timeIndicatorSize: timeLabelSize)
    }

    func updateWith(vibroChatMessage: VibroChatMessageViewModel,
                    maxWidth: CGFloat,
                    layout: VibroChatMessageViewLayout? = nil) -> VibroChatMessageViewLayout {
        let layout = layout ?? type(of: self).layoutWith(vibroChatMessage: vibroChatMessage, maxWidth: maxWidth)

        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeLabel.frame = CGRect(origin: self.timeLabel.frame.origin, size: layout.timeIndicatorSize)

        self.setMessageViewColorsWith(message: vibroChatMessage)
        self.timeLabel.text = vibroChatMessage.creationTimeDescription
        self.titleLabel.text = SenderFrameworkLocalizedString("vibro_chat")

        self.setNeedsLayout()

        return layout
    }

    func setMessageViewColorsWith(message: MessageViewModel) {
        let ownerMessageColor: UIColor
        let foreignMessageColor: UIColor
        let ownerBorderColor: UIColor
        let foreignBorderColor: UIColor

        if message.isEncrypted {
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

        self.setNewBackgroundColor(message.author == .owner ? ownerMessageColor : foreignMessageColor)
        self.layer.borderColor = (message.author == .owner ? ownerBorderColor : foreignBorderColor).cgColor
    }

    func setNewBackgroundColor(_ newBackgroundColor: UIColor) {
        self.backgroundColor = newBackgroundColor
        self.timeLabel.backgroundColor = newBackgroundColor
        self.titleLabel.backgroundColor = newBackgroundColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2

        self.vibroChatImageView.frame = CGRect(x: type(of: self).vibroChatImageLeading,
                                               y: (self.frame.height - type(of: self).vibroChatImageSide) / 2,
                                               width: type(of: self).vibroChatImageSide,
                                               height: type(of: self).vibroChatImageSide)

        let timeLabelX = self.frame.width - self.timeLabel.frame.width - type(of: self).timeLabelTrailing
        let timeLabelY = self.frame.height - self.timeLabel.frame.height - type(of: self).timeLabelBottom
        let timeLabelOrigin = CGPoint(x: timeLabelX, y: timeLabelY)
        self.timeLabel.frame = CGRect(origin: timeLabelOrigin, size: self.timeLabel.frame.size)

        let titleLabelX = self.vibroChatImageView.frame.maxX + type(of: self).titleToVibroChatImageLeading
        let titleLabelWidth = self.timeLabel.frame.minX - type(of: self).timeLabelToTitleLeading - titleLabelX
        let titleLabelFrame = CGRect(x: titleLabelX,
                                     y: (self.frame.height - type(of: self).titleLabelHeight) / 2,
                                     width: titleLabelWidth,
                                     height: type(of: self).titleLabelHeight)
        self.titleLabel.frame = titleLabelFrame
    }
}
