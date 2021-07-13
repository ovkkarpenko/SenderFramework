//
// Created by Roman Serga on 6/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class ImageMessageView: MediaMessageView {

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

    override func setContent(_ content: UIView?) {
        super.setContent(content)
        if let activityIndicator = activityIndicator {
            activityIndicator.removeFromSuperview()
            self.containerView.addSubview(activityIndicator)
        }
    }

    func updateWith(imageMessage: ImageMessageViewModel,
                    maxWidth: CGFloat,
                    layout: MediaMessageViewLayout? = nil) -> MediaMessageViewLayout {
        let layout = super.updateWith(message: imageMessage, maxWidth: maxWidth, layout: layout)
        self.setContent(self.defaultImageView)
        self.defaultImageView.defaultEmoji = imageMessage.defaultPreviewText
        self.isBorderVisible = true
        self.isActivityIndicatorHidden = !imageMessage.isLoadingMedia

        if let previewURL = imageMessage.previewURL {
            self.imageView.sd_setImage(with: previewURL) { image, _, _, _ in
                if image != nil {
                    self.fixImageViewContentMode()
                    self.setContent(self.imageView)
                    self.isBorderVisible = false
                }
            }
        }
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
    }
}
