//
// Created by Roman Serga on 6/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    mutating func mw_round() {
        self.origin = CGPoint(x: ceil(self.origin.x), y: ceil(self.origin.y))
        self.size = CGSize(width: ceil(self.size.width), height: ceil(self.size.height))
    }

    func mw_rounded() -> CGRect {
        return CGRect(x: ceil(self.origin.x),
                      y: ceil(self.origin.y),
                      width: ceil(self.size.width),
                      height: ceil(self.size.height))
    }
}

protocol BaseMessageContainerCellActionHandler: class {
    func messageContainerCell(_ messageContainerCell: BaseMessageContainerCell,
                              didSelectAction action: MessageViewAction)
    func messageContainerCell(_ messageContainerCell: BaseMessageContainerCell,
                              canPerformAction action: MessageViewAction) -> Bool
}

class BaseMessageContainerCell: UICollectionViewCell, MessageViewActionHandler {
    weak var actionHandler: BaseMessageContainerCellActionHandler?
    weak var messageView: MessageView?

    var maxContainerViewWidth: CGFloat { return self.frame.width }
    var minimalHeight: CGFloat { return 0.0 }

    fileprivate var containerViewSize: CGSize = .zero
    fileprivate weak var content: UIView?

    let containerView: UIView = {
        let containerView = UIView()
        return containerView
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
        self.contentView.addSubview(self.containerView)
        self.containerView.backgroundColor = .white
        self.backgroundColor = .white
        self.isOpaque = true
        self.alpha = 1.0
        self.layer.drawsAsynchronously = true
    }

    func sizeWith(contentSize: CGSize) -> CGSize {
        let newHeight = contentSize.height >= self.minimalHeight ? contentSize.height : self.minimalHeight
        return CGSize(width: self.frame.width, height: newHeight)
    }

    func setContent(_ content: UIView?) {
        self.containerView.subviews.forEach { $0.removeFromSuperview() }
        self.content = content
        if let content = content { self.containerView.addSubview(content) }
        self.changeSizeWithContent(content)
    }

    func changeSizeWithContent(_ content: UIView?) {
        self.containerViewSize = content?.frame.size ?? .zero
        if self.containerViewSize.width > self.maxContainerViewWidth {
            self.containerViewSize.width = self.maxContainerViewWidth
        }
        let newSize = self.sizeWith(contentSize: self.containerViewSize)
        self.frame = CGRect(origin: self.frame.origin, size: newSize)
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let containerViewX = CGFloat(0.0)
        let containerViewY = CGFloat(0.0)
        let containerViewOrigin = CGPoint(x: containerViewX, y: containerViewY)
        self.containerView.frame = CGRect(origin: containerViewOrigin, size: self.containerViewSize)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.setContent(nil)
    }

    func messageView(_ messageView: MessageView, didSelectAction action: MessageViewAction) {
        self.actionHandler?.messageContainerCell(self, didSelectAction: action)
    }

    func messageView(_ messageView: MessageView, canPerformAction action: MessageViewAction) -> Bool {
        return self.actionHandler?.messageContainerCell(self, canPerformAction: action) ?? true
    }

    func handleUpdate(_ messageViewUpdate: MessageViewUpdate!) {
        self.messageView?.handleUpdate(messageViewUpdate)
    }
}

class NotificationContainerCell: BaseMessageContainerCell {
    var containerViewMinHorizontalOffset: CGFloat { return 8.0 }
    override var maxContainerViewWidth: CGFloat { return self.frame.width - 2 * self.containerViewMinHorizontalOffset}

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let containerViewX = (self.frame.width - self.containerViewSize.width) / 2
        let containerViewY = CGFloat(0.0)
        let containerViewOrigin = CGPoint(x: containerViewX, y: containerViewY)
        self.containerView.frame = CGRect(origin: containerViewOrigin, size: self.containerViewSize)

        self.content?.frame = self.containerView.bounds
    }
}

class OwnerMessageContainerCell: BaseMessageContainerCell {
    var statusLabelTop: CGFloat { return 3.0 }
    var statusLabelTrailing: CGFloat { return self.containerViewTrailing }
    var statusLabelMinLeading: CGFloat { return containerViewMinLeading }
    var statusLabelMaxHeight: CGFloat { return 14.0 }

    var containerViewMinLeading: CGFloat { return 8.0 }
    var containerViewTrailing: CGFloat { return 8.0 }

    override var minimalHeight: CGFloat { return 0.0 }

    override var maxContainerViewWidth: CGFloat {
        return self.frame.width - self.containerViewTrailing - self.containerViewMinLeading
    }

    var maxStatusWidth: CGFloat {
        return self.contentView.frame.size.width - self.statusLabelTrailing - self.statusLabelMinLeading
    }

    let statusLabel: UILabel = {
        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 11.0)
        statusLabel.backgroundColor = .white
        statusLabel.alpha = 1.0
        statusLabel.isOpaque = true
        return statusLabel
    }()

    var statusHidden = false {
        didSet {
            if oldValue != statusHidden { self.setNeedsLayout() }
        }
    }

    override func setUp() {
        super.setUp()
        self.contentView.addSubview(self.statusLabel)
    }

    override func sizeWith(contentSize: CGSize) -> CGSize {
        var calculatedHeight = contentSize.height

        let statusLabelHeight: CGFloat
        let statusLabelTop: CGFloat
        if self.statusHidden {
            statusLabelHeight = 0.0
            statusLabelTop = 0.0
        } else {
            statusLabelHeight = self.statusLabelMaxHeight
            statusLabelTop = self.statusLabelTop
        }
        calculatedHeight += statusLabelHeight + statusLabelTop

        let newHeight = calculatedHeight >= self.minimalHeight ? calculatedHeight : self.minimalHeight
        return CGSize(width: self.frame.width, height: newHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let containerViewX = self.frame.width - self.containerViewSize.width - self.containerViewTrailing
        let containerViewY = CGFloat(0.0)
        let containerViewOrigin = CGPoint(x: containerViewX, y: containerViewY)
        self.containerView.frame = CGRect(origin: containerViewOrigin, size: self.containerViewSize)

        let statusLabelSize: CGSize
        let statusLabelY: CGFloat
        if self.statusHidden {
            statusLabelSize = .zero
            statusLabelY = 0.0
        } else {
            let maxStatusSize = CGSize(width: self.maxStatusWidth, height: self.statusLabelMaxHeight)
            let sizeToFitStatus = self.statusLabel.attributedText?.boundingRect(with: maxStatusSize,
                                                                                context: nil).mw_rounded().size
            statusLabelSize = sizeToFitStatus ?? .zero
            statusLabelY = self.containerView.frame.maxY + self.statusLabelTop
        }

        let statusLabelX = self.frame.width - statusLabelSize.width - self.statusLabelTrailing
        let statusLabelOrigin = CGPoint(x: statusLabelX, y: statusLabelY)
        self.statusLabel.frame = CGRect(origin: statusLabelOrigin, size: statusLabelSize)

        self.content?.frame = self.containerView.bounds
    }
}

extension MessageViewAction {
    static var openChat: MessageViewAction {
        return MessageViewAction(name: "openChat")
    }
}

class InterlocutorMessageContainerCell: BaseMessageContainerCell {

    let profilePhotoSize: CGSize = CGSize(width: 32, height: 32)
    let profilePhotoLeading: CGFloat = 8.0
    let profilePhotoTrailing: CGFloat = 8.0

    let minProfileNameTrailing: CGFloat = 8.0
    let maxProfileNameHeight: CGFloat = 13.0
    let profileNameBottom: CGFloat = 4.0

    let containerViewMinTrailing: CGFloat = 8.0

    override var minimalHeight: CGFloat { return self.profilePhotoHidden ? 0.0 : self.profilePhotoSize.height }

    var profilePhotoHidden = false {
        didSet {
            self.profilePhotoButton.isHidden = self.profilePhotoHidden
        }
    }

    var profileNameHidden = false {
        didSet {
            self.profileNameLabel.isHidden = self.profileNameHidden
            if oldValue != self.profileNameHidden { self.setNeedsLayout() }
        }
    }

    override var maxContainerViewWidth: CGFloat {
        return self.frame.width -
               self.containerViewMinTrailing -
               self.profilePhotoButton.frame.maxX -
               self.profilePhotoTrailing
    }

    let profilePhotoButton: UIButton = {
        let profilePhotoImage = UIButton(type: .custom)
        profilePhotoImage.alpha = 1.0
        profilePhotoImage.backgroundColor = .white
        profilePhotoImage.layer.masksToBounds = true
        return profilePhotoImage
    }()

    let profileNameLabel: UILabel = {
        let profileNameLabel = UILabel()
        profileNameLabel.font = SenderCore.shared().stylePalette.inputTextFieldFontStyle(nil, andSize:12)
        profileNameLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        profileNameLabel.numberOfLines = 0
        profileNameLabel.backgroundColor = .white
        return profileNameLabel
    }()

    override func setUp() {
        super.setUp()
        self.contentView.addSubview(self.profileNameLabel)
        self.contentView.addSubview(self.profilePhotoButton)
        self.profilePhotoButton.addTarget(self, action: #selector(profilePhotoButtonPressed), for: .touchUpInside)
    }

    override func sizeWith(contentSize: CGSize) -> CGSize {
        let profileNameSize: CGSize
        let profileNameBottomFixed: CGFloat
        if self.profileNameHidden {
            profileNameSize = .zero
            profileNameBottomFixed = 0.0
        } else {
            let profileNameOrigin = CGPoint(x: self.profilePhotoButton.frame.maxX + self.profilePhotoTrailing, y: 0.0)
            let maxNameWidth = self.contentView.frame.size.width - profileNameOrigin.x - self.minProfileNameTrailing
            profileNameSize = CGSize(width: maxNameWidth, height: self.maxProfileNameHeight)
            profileNameBottomFixed = self.profileNameBottom
        }
        let calculatedHeight = contentSize.height + profileNameSize.height + profileNameBottomFixed
        let newHeight = calculatedHeight >= self.minimalHeight ? calculatedHeight : self.minimalHeight
        return CGSize(width: self.frame.width, height: newHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let profilePhotoX = self.profilePhotoLeading
        let profilePhotoY = CGFloat(0.0)
        let profilePhotoOrigin = CGPoint(x: profilePhotoX, y: profilePhotoY)
        self.profilePhotoButton.frame = CGRect(origin: profilePhotoOrigin, size: self.profilePhotoSize)

        let profileNameOrigin = CGPoint(x: self.profilePhotoButton.frame.maxX + self.profilePhotoTrailing, y: 0.0)
        let profileNameSize: CGSize
        let profileNameBottomFixed: CGFloat
        if self.profileNameHidden {
            profileNameSize = .zero
            profileNameBottomFixed = 0.0
        } else {
            let maxNameWidth = self.contentView.frame.size.width - profileNameOrigin.x - self.minProfileNameTrailing
            profileNameSize = CGSize(width: maxNameWidth, height: self.maxProfileNameHeight)
            profileNameBottomFixed = self.profileNameBottom
        }
        self.profileNameLabel.frame = CGRect(origin: profileNameOrigin, size: profileNameSize)

        let containerViewX = self.profilePhotoButton.frame.maxX + self.profilePhotoTrailing
        let containerViewY = self.profileNameLabel.frame.maxY + profileNameBottomFixed
        let containerViewOrigin = CGPoint(x: containerViewX, y: containerViewY)
        self.containerView.frame = CGRect(origin: containerViewOrigin, size: self.containerViewSize)

        self.content?.frame = self.containerView.bounds
    }

    @objc func profilePhotoButtonPressed() {
        let canPerformAction: Bool
        let action: MessageViewAction = .openChat
        if let actionHandler = self.actionHandler {
            canPerformAction = actionHandler.messageContainerCell(self, canPerformAction: action)
        } else {
            canPerformAction = true
        }
        if canPerformAction {
            self.actionHandler?.messageContainerCell(self, didSelectAction: action)
        }
    }
}
