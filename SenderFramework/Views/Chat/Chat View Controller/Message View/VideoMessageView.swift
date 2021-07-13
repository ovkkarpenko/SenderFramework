//
// Created by Roman Serga on 8/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class VideoMessageView: MediaMessageView {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .black
        return imageView
    }()

    let defaultImageView: DefaultMediaView = {
        let defaultImageView = DefaultMediaView()
        defaultImageView.backgroundColor = .clear
        return defaultImageView
    }()

    let playImage: UIImageView = {
        let playImage = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 42.0, height: 42.0))
        playImage.image = UIImage(fromSenderFrameworkNamed: "icPlayVideo")?.withRenderingMode(.alwaysTemplate)
        playImage.contentMode = .center
        playImage.tintColor = .white
        playImage.backgroundColor = SenderCore.shared().stylePalette.chatNotificationBackgroundColor
        return playImage
    }()

    var isPlayImageHidden: Bool {
        get {
            return self.playImage.isHidden
        }
        set {
            self.playImage.isHidden = newValue
        }
    }

    override func setUp() {
        super.setUp()
        self.containerView.addSubview(self.playImage)
    }

    override func setContent(_ content: UIView?) {
        super.setContent(content)
        self.playImage.removeFromSuperview()
        self.containerView.addSubview(self.playImage)
    }

    func updateWith(videoMessage: VideoMessageViewModel,
                    maxWidth: CGFloat,
                    layout: MediaMessageViewLayout? = nil) -> MediaMessageViewLayout {
        let layout = super.updateWith(message: videoMessage, maxWidth: maxWidth, layout: layout)
        self.setContent(self.defaultImageView)
        self.defaultImageView.defaultEmoji = videoMessage.defaultPreviewText
        self.isBorderVisible = true
        self.isActivityIndicatorHidden = !videoMessage.isLoadingMedia

        if let previewURL = videoMessage.previewURL {
            self.imageView.sd_setImage(with: previewURL) { image, _, _, _ in
                if image != nil {
                    self.fixImageViewContentMode()
                    self.setContent(self.imageView)
                    self.isBorderVisible = false
                }
            }
        }

        self.isPlayImageHidden = videoMessage.isLoadingMedia
        return layout
    }

    func fixImageViewContentMode() {
        if let contentImage = self.imageView.image {
            if contentImage.size.width >= self.imageView.frame.width &&
                       contentImage.size.height >= self.imageView.frame.height {
                self.imageView.contentMode = .scaleAspectFill
            } else {
                self.imageView.contentMode = .center
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.fixImageViewContentMode()

        let playImageX = (self.containerView.frame.width - self.playImage.frame.width) / 2
        let playImageY = (self.containerView.frame.height - self.playImage.frame.height) / 2
        let playImageOrigin = CGPoint(x: playImageX, y: playImageY)
        self.playImage.frame = CGRect(origin: playImageOrigin, size: self.playImage.frame.size)

        self.playImage.layer.cornerRadius = self.playImage.frame.height / 2
    }
}
