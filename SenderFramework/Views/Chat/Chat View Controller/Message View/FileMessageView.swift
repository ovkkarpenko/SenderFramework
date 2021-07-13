//
// Created by Roman Serga on 28/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class FileMessageViewLayout: MessageWithTimeLayout {}

class FileMessageView: MessageView {
    static let fileButtonSide: CGFloat = 29.0
    static let fileButtonLeading: CGFloat = 4.0
    static let fileButtonTrailing: CGFloat = 4.0

    static let fileSizeLabelWidth: CGFloat = 0.0
    static let fileSizeLabelHeight: CGFloat = 0.0
    static let fileSizeToFileButtonLeading: CGFloat = 0.0
    static let fileNameToFileSizeLeading: CGFloat = 8.0

    static let timeLabelToFileNameLeading: CGFloat = 8.0
    static let timeLabelTrailing: CGFloat = 12.0
    static let timeLabelBottom: CGFloat = 8.0

    static let fileNameHeight: CGFloat = 20.0

    static let timeLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0)

    static let fileNameFont: UIFont = SenderCore.shared().stylePalette.inputTextFieldFontStyle(nil, andSize: 16)
    static let fileNameTextColor: UIColor = SenderCore.shared().stylePalette.mainTextColor

    static let maxHeight: CGFloat = 36.0

    let fileButton: UIButton = {
        let fileButton = UIButton()
        fileButton.setImage(UIImage(fromSenderFrameworkNamed: "icFile"), for: .normal)
        fileButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        return fileButton
    }()

    let fileSizeLabel: UILabel = {
        let fileSizeLabel = UILabel()
        fileSizeLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        fileSizeLabel.font = UIFont.systemFont(ofSize: 12.0)
        fileSizeLabel.textAlignment = .center

        return fileSizeLabel
    }()

    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        timeLabel.textAlignment = .center
        return timeLabel
    }()

    let fileNameLabel: UILabel = {
        let fileNameLabel = UILabel()
        fileNameLabel.font = FileMessageView.fileNameFont
        fileNameLabel.textColor = FileMessageView.fileNameTextColor
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        return fileNameLabel
    }()

    var isLoadingFile = false {
        didSet {
            guard self.isLoadingFile != oldValue else { return }
            if self.isLoadingFile {
                let frames = (1...12).flatMap { UIImage(fromSenderFrameworkNamed: "icFilePreloader" + String($0)) }
                let activityIndicator = UIImage.animatedImage(with: frames, duration: 0.8)
                self.fileButton.setImage(activityIndicator, for: .normal)
            } else {
                self.fileButton.setImage(UIImage(fromSenderFrameworkNamed: "icFile"), for: .normal)
            }
            self.setNeedsLayout()
        }
    }

    override func setUp() {
        super.setUp()
        self.layer.borderWidth = 1.0
        timeLabel.font = type(of: self).timeLabelFont
        self.addSubview(self.fileSizeLabel)
        self.addSubview(self.timeLabel)
        self.addSubview(self.fileButton)
        self.addSubview(self.fileNameLabel)
        self.fileButton.addTarget(self, action: #selector(self.performAction), for: .touchUpInside)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    convenience init() {
        let frame = CGRect()
        self.init(frame: frame)
    }

    static func layoutWith(fileMessage: FileMessageViewModel, maxWidth: CGFloat) -> FileMessageViewLayout {
        let elementsWidth = self.fileButtonLeading + self.fileButtonSide + self.fileSizeToFileButtonLeading +
                self.fileSizeLabelWidth + self.fileNameToFileSizeLeading +
                self.timeLabelToFileNameLeading + self.timeLabelTrailing
        let maxTimeWidth = maxWidth - elementsWidth
        let attributedTimeLabelText = NSAttributedString(string: fileMessage.creationTimeDescription ?? "",
                                                         attributes: [.font: self.timeLabelFont])
        let timeSizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let maxTimeLabelSize = CGSize(width: maxTimeWidth, height: self.maxHeight)
        let timeLabelSize = attributedTimeLabelText.boundingRect(with: maxTimeLabelSize,
                                                                 options: timeSizeCalculateOptions,
                                                                 context: nil).mw_rounded().size

        let fileNameAttributes = [.font: self.fileNameFont,
                                  NSAttributedStringKey(rawValue: "NSOriginalFont"): self.fileNameFont]
        let fileNameString = NSAttributedString(string: fileMessage.fileName, attributes: fileNameAttributes)
        let maxFileNameWidth = maxWidth - elementsWidth - timeLabelSize.width
        let maxFileNameSize = CGSize(width: maxFileNameWidth, height: self.maxHeight)
        let sizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let fileNameLabelEstimatedSize = fileNameString.boundingRect(with: maxFileNameSize,
                                                                     options: sizeCalculateOptions,
                                                                     context: nil).mw_rounded()
        let viewWidth = elementsWidth + timeLabelSize.width + fileNameLabelEstimatedSize.width
        let viewSize = CGSize(width: viewWidth, height: self.maxHeight)
        return FileMessageViewLayout(size: viewSize, timeIndicatorSize: timeLabelSize)
    }

    func updateWith(fileMessage: FileMessageViewModel,
                    maxWidth: CGFloat,
                    layout: FileMessageViewLayout?) -> FileMessageViewLayout {
        let layout = layout ?? type(of: self).layoutWith(fileMessage: fileMessage, maxWidth: maxWidth)
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeLabel.frame = CGRect(origin: self.timeLabel.frame.origin, size: layout.timeIndicatorSize)

        self.setMessageViewColorsWith(message: fileMessage)
        self.timeLabel.text = fileMessage.creationTimeDescription
        self.fileNameLabel.text = fileMessage.fileName
        self.isLoadingFile = fileMessage.isLoadingFile

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
        self.fileNameLabel.backgroundColor = newBackgroundColor
        self.timeLabel.backgroundColor = newBackgroundColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2

        self.fileButton.frame = self.bounds
        self.fileButton.contentHorizontalAlignment = .left
        self.fileButton.frame = CGRect(x: type(of: self).fileButtonLeading,
                                       y: (self.frame.height - type(of: self).fileButtonSide) / 2,
                                       width: self.frame.width - type(of: self).fileButtonTrailing,
                                       height: type(of: self).fileButtonSide)

        let fileImageMaxX = (self.fileButton.imageView?.frame.maxX ?? CGFloat(0.0))
        let fileSizeLabelX = self.fileButton.frame.origin.x + fileImageMaxX + type(of: self).fileSizeToFileButtonLeading
        self.fileSizeLabel.frame = CGRect(x: fileSizeLabelX,
                                          y: (self.frame.height - type(of: self).fileSizeLabelHeight) / 2,
                                          width: type(of: self).fileSizeLabelWidth,
                                          height: type(of: self).fileSizeLabelHeight)

        let timeLabelX = self.frame.width - self.timeLabel.frame.width - type(of: self).timeLabelTrailing
        let timeLabelY = self.frame.height - self.timeLabel.frame.height - type(of: self).timeLabelBottom
        let timeLabelOrigin = CGPoint(x: timeLabelX, y: timeLabelY)
        self.timeLabel.frame = CGRect(origin: timeLabelOrigin, size: self.timeLabel.frame.size)

        let fileNameX = self.fileSizeLabel.frame.maxX + type(of: self).fileNameToFileSizeLeading
        let fileNameWidth = self.timeLabel.frame.minX - type(of: self).timeLabelToFileNameLeading - fileNameX
        let fileNameFrame = CGRect(x: fileNameX,
                                   y: (self.frame.height - type(of: self).fileNameHeight) / 2,
                                   width: fileNameWidth,
                                   height: type(of: self).fileNameHeight)
        self.fileNameLabel.frame = fileNameFrame
    }

    @objc open func performAction() {
        let canPerformAction: Bool

        if let actionsHandler = self.actionsHandler {
            canPerformAction = actionsHandler.messageView(self, canPerformAction: .openMedia)
        } else {
            canPerformAction = true
        }

        if canPerformAction { self.actionsHandler?.messageView(self, didSelectAction: .openMedia) }
    }
}
