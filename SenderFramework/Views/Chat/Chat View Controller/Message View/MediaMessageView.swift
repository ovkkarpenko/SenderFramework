//
// Created by Roman Serga on 6/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class DefaultMediaView: UIView {

    let emojiLabelHeight: CGFloat = 84.0
    let emojiLabelWidth: CGFloat = 64.0

    public var defaultEmoji: String? {
        get {
            return self.emojiLabel.text
        }
        set {
            self.emojiLabel.text = newValue
        }
    }

    let emojiLabel: UILabel = {
        let emojiLabel = UILabel()
        emojiLabel.backgroundColor = .clear
        emojiLabel.font = UIFont(name: "AppleColorEmoji", size: 64)
        return emojiLabel
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    func setUp() {
        self.addSubview(self.emojiLabel)
        self.emojiLabel.frame =  CGRect(x: 0.0, y: 0.0, width: self.emojiLabelWidth, height: self.emojiLabelHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let emojiLabelX = (self.frame.width - self.emojiLabel.frame.width) / 2
        let emojiLabelY = (self.frame.height - self.emojiLabel.frame.height) / 2
        let emojiLabelOrigin = CGPoint(x: emojiLabelX, y: emojiLabelY)
        self.emojiLabel.frame = CGRect(origin: emojiLabelOrigin, size: self.emojiLabel.frame.size)
    }
}

class MessageActivityIndicatorView: UIView {

    let activityIndicatorWidth: CGFloat = 14.0
    let activityIndicatorHeight: CGFloat = 14.0

    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicatorView.tintColor = .white
        return activityIndicatorView
    }()

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            /*
             * Calling asynchronously in order to fix CATransaction completionHandler bug.
             * http://stackoverflow.com/questions/27470130/catransaction-completion-block-never-fires
             */
            DispatchQueue.main.async { self.activityIndicatorView.startAnimating() }
        } else {
            self.activityIndicatorView.stopAnimating()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    func setUp() {
        self.backgroundColor = SenderCore.shared().stylePalette.chatNotificationBackgroundColor
        self.addSubview(self.activityIndicatorView)
        self.activityIndicatorView.frame = CGRect(x: 0.0,
                                                  y: 0.0,
                                                  width: self.activityIndicatorWidth,
                                                  height: self.activityIndicatorHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let activityIndicatorX = (self.frame.width - self.activityIndicatorView.frame.width) / 2
        let activityIndicatorY = (self.frame.height - self.activityIndicatorView.frame.height) / 2
        let activityIndicatorOrigin = CGPoint(x: activityIndicatorX, y: activityIndicatorY)
        self.activityIndicatorView.frame = CGRect(origin: activityIndicatorOrigin,
                                                  size: self.activityIndicatorView.frame.size)
        self.layer.cornerRadius = self.frame.height / 2
    }
}

class MessageTimeView: UIView {

    static let timeLabelHorizontalOffset: CGFloat = 8.0
    static let timeLabelVerticalOffset: CGFloat = 2.0
    static let timeLabelFont = UIFont.systemFont(ofSize: 12.0)

    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        return timeLabel
    }()

    var timeString: String? {
        get {
            return timeLabel.text
        }
        set {
            self.timeLabel.text = newValue
            self.invalidateIntrinsicContentSize()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    func setUp() {
        self.backgroundColor = SenderCore.shared().stylePalette.chatNotificationBackgroundColor
        self.addSubview(self.timeLabel)
        timeLabel.font = type(of: self).timeLabelFont
    }

    static func sizeWith(timeString: String, maxWidth: CGFloat) -> CGSize {
        let sizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let attributedTimeString = NSAttributedString(string: timeString, attributes: [.font: self.timeLabelFont])
        let maxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var timeSize = attributedTimeString.boundingRect(with: maxSize,
                                                         options: sizeCalculateOptions,
                                                         context: nil).mw_rounded().size
        timeSize.width += 2 * self.timeLabelHorizontalOffset
        timeSize.height += 2 * self.timeLabelVerticalOffset
        return timeSize
    }

    override var intrinsicContentSize: CGSize {
        var viewIntrinsicContentSize = self.timeLabel.intrinsicContentSize
        viewIntrinsicContentSize.width += 2 * type(of: self).timeLabelHorizontalOffset
        viewIntrinsicContentSize.height += 2 * type(of: self).timeLabelVerticalOffset
        return viewIntrinsicContentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let timeLabelWidth = self.frame.width - 2 * type(of: self).timeLabelHorizontalOffset
        let timeLabelHeight = self.frame.height - 2 * type(of: self).timeLabelVerticalOffset
        self.timeLabel.frame = CGRect(x: type(of: self).timeLabelHorizontalOffset,
                                      y: type(of: self).timeLabelVerticalOffset,
                                      width: timeLabelWidth,
                                      height: timeLabelHeight)
        self.layer.cornerRadius = self.frame.height / 2
    }
}

extension MessageViewAction {
    static var openMedia: MessageViewAction {
        return MessageViewAction(name: "openMedia")
    }
}

class MediaMessageViewLayout: MessageWithTimeLayout { }

class MediaMessageView: MessageView {

    static let timeViewBottomOffset: CGFloat = 8.0
    static let timeViewTrailingOffset: CGFloat = 8.0

    fileprivate weak var contentView: UIView?

    let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        return containerView
    }()

    let actionButton: UIButton = {
        let actionButton = UIButton()
        actionButton.backgroundColor = .clear
        actionButton.setTitle(nil, for: .normal)
        return actionButton
    }()

    let timeView: MessageTimeView = {
        let timeView = MessageTimeView()
        return timeView
    }()

    var activityIndicator: MessageActivityIndicatorView?

    var isActivityIndicatorHidden: Bool {
        get {
            return self.activityIndicator != nil
        }
        set {
            if newValue {
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            } else {
                let activityIndicator = MessageActivityIndicatorView(frame: CGRect(x: 0.0,
                                                                                   y: 0.0,
                                                                                   width: 42.0,
                                                                                   height: 42.0))
                self.containerView.addSubview(activityIndicator)
                self.activityIndicator = activityIndicator
            }
        }
    }

    var isBorderVisible: Bool {
        get {
            return self.layer.borderWidth != 0.0
        }
        set {
            self.layer.borderWidth = newValue ? 1.0 : 0.0
        }
    }

    static func layoutWith(message: MessageViewModel, maxWidth: CGFloat) -> MediaMessageViewLayout {
        let defaultWidth: CGFloat = 247.0
        let defaultHeight: CGFloat = 208.0
        let viewSize: CGSize
        if maxWidth < defaultWidth {
            let scale = maxWidth / defaultWidth
            let height = defaultHeight * scale
            viewSize = CGSize(width: maxWidth, height: height)
        } else {
            viewSize = CGSize(width: defaultWidth, height: defaultHeight)
        }
        let maxTimeViewWidth = maxWidth - self.timeViewTrailingOffset
        let timeViewSize = MessageTimeView.sizeWith(timeString: message.creationTimeDescription ?? "",
                                                    maxWidth: maxTimeViewWidth)
        return MediaMessageViewLayout(size: viewSize, timeIndicatorSize: timeViewSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setUp() {
        self.backgroundColor = .white
        self.alpha = 1.0
        self.addSubview(self.containerView)
        self.addSubview(self.timeView)
        self.addSubview(self.actionButton)
        self.actionButton.addTarget(self, action: #selector(self.performAction), for: .touchUpInside)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    func setContent(_ content: UIView?) {
        self.containerView.subviews.forEach { $0.removeFromSuperview() }
        self.contentView = content
        if let content = content { self.containerView.addSubview(content) }
        if let activityIndicator = activityIndicator {
            activityIndicator.removeFromSuperview()
            self.containerView.addSubview(activityIndicator)
        }
        self.setNeedsLayout()
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

    func updateWith(message: MessageViewModel,
                    maxWidth: CGFloat,
                    layout: MediaMessageViewLayout? = nil) -> MediaMessageViewLayout {
        self.timeView.timeString = message.creationTimeDescription
        self.setMessageViewColorsWith(message: message)
        let layout = layout ?? type(of: self).layoutWith(message: message, maxWidth: maxWidth)
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeView.frame = CGRect(origin: self.timeView.frame.origin, size: layout.timeIndicatorSize)
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

        self.backgroundColor = message.author == .owner ? ownerMessageColor : foreignMessageColor
        self.layer.borderColor = (message.author == .owner ? ownerBorderColor : foreignBorderColor).cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 18.0
        self.layer.masksToBounds = true
        self.containerView.frame = self.bounds
        self.contentView?.frame = self.containerView.bounds
        self.actionButton.frame = self.bounds

        let timeViewSize = self.timeView.frame.size
        let timeViewX = self.containerView.frame.maxX - type(of: self).timeViewTrailingOffset - timeViewSize.width
        let timeViewY = self.containerView.frame.maxY - type(of: self).timeViewBottomOffset - timeViewSize.height
        let timeViewOrigin = CGPoint(x: timeViewX, y: timeViewY)
        self.timeView.frame = CGRect(origin: timeViewOrigin, size: timeViewSize)

        if let activityIndicator = activityIndicator {
            let activityIndicatorX = (self.containerView.frame.width - activityIndicator.frame.width) / 2
            let activityIndicatorY = (self.containerView.frame.height - activityIndicator.frame.height) / 2
            let activityIndicatorOrigin = CGPoint(x: activityIndicatorX, y: activityIndicatorY)
            activityIndicator.frame = CGRect(origin: activityIndicatorOrigin, size: activityIndicator.frame.size)
        }
    }
}
