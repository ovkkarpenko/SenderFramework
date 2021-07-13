//
// Created by Roman Serga on 8/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class StickerMessageViewLayout: MessageWithTimeLayout {}

class StickerMessageView: MessageView {

    enum StickerAlignment {
        case left
        case right
    }

    static let timeViewBottomOffset: CGFloat = 0.0
    static let timeViewTrailingOffset: CGFloat = 0.0

    var stickerAlignment: StickerAlignment = .left

    let stickerImage: UIImageView = {
        let stickerImage = UIImageView()
        stickerImage.backgroundColor = .clear
        stickerImage.contentMode = .scaleAspectFit
        return stickerImage
    }()

    let timeView: MessageTimeView = {
        let timeView = MessageTimeView()
        return timeView
    }()

    static func layoutWith(stickerMessage: StickerMessageViewModel, maxWidth: CGFloat) -> StickerMessageViewLayout {
        let maxTimeViewWidth = maxWidth - self.timeViewTrailingOffset
        let timeViewSize = MessageTimeView.sizeWith(timeString: stickerMessage.creationTimeDescription ?? "",
                                                    maxWidth: maxWidth - maxTimeViewWidth)
        let defaultHeight: CGFloat = 125.0
        let viewSize = CGSize(width: maxWidth, height: defaultHeight)
        return StickerMessageViewLayout(size: viewSize, timeIndicatorSize: timeViewSize)
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
        self.addSubview(self.stickerImage)
        self.addSubview(self.timeView)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    func updateWith(stickerMessage: StickerMessageViewModel,
                    maxWidth: CGFloat,
                    layout: StickerMessageViewLayout?) -> StickerMessageViewLayout {
        let layout = layout ?? type(of: self).layoutWith(stickerMessage: stickerMessage, maxWidth: maxWidth)

        self.timeView.timeString = stickerMessage.creationTimeDescription
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeView.frame = CGRect(origin: self.timeView.frame.origin, size: layout.timeIndicatorSize)

        if let stickerURL = stickerMessage.stickerURL {
            self.stickerImage.sd_setImage(with: stickerURL) { _, _, _, _ in
                self.fixImageViewContentMode()
                self.setNeedsLayout()
            }
        }

        self.stickerAlignment = stickerMessage.author == .owner ? .right : .left

        return layout
    }

    func fixImageViewContentMode() {
        if let contentImage = self.stickerImage.image {
            if contentImage.size.width >= self.stickerImage.frame.width &&
                       contentImage.size.height >= self.stickerImage.frame.height {
                self.stickerImage.contentMode = .scaleAspectFit
            } else {
                self.stickerImage.contentMode = .center
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let stickerImageHeight = self.frame.height
        let stickerImageWidth: CGFloat
        let isStickerImageHidden: Bool
        if let stickerImage = self.stickerImage.image {
            let imageAspectRatio = stickerImage.size.width / stickerImage.size.height
            let calculatedWidth = stickerImageHeight * imageAspectRatio
            stickerImageWidth = calculatedWidth <= self.frame.width ? calculatedWidth : self.frame.width
            isStickerImageHidden = false
        } else {
            stickerImageWidth = 100.0
            isStickerImageHidden = true
        }
        let stickerImageX: CGFloat
        if self.stickerAlignment == .left {
            stickerImageX = 0.0
        } else {
            stickerImageX = self.frame.width - stickerImageWidth
        }

        self.stickerImage.isHidden = isStickerImageHidden
        self.stickerImage.frame = CGRect(x: stickerImageX,
                                         y: 0.0,
                                         width: stickerImageWidth,
                                         height: stickerImageHeight)

        self.fixImageViewContentMode()

        let timeViewX = self.stickerImage.frame.maxX - type(of: self).timeViewTrailingOffset - self.timeView.frame.width
        let timeViewY = self.stickerImage.frame.maxY - type(of: self).timeViewBottomOffset - self.timeView.frame.height
        self.timeView.frame = CGRect(origin: CGPoint(x: timeViewX, y: timeViewY), size: self.timeView.frame.size)
    }
}
