//
// Created by Roman Serga on 22/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatTypingIndicator: NotificationMessageView {

    override class var maximumNumberOfLines: Int { return 1 }

    var text: String? {
        get {
            return self.textView.text
        }
        set {
            self.textView.text = newValue
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return NotificationMessageView.layoutWith(text: self.text ?? "", maxWidth: .greatestFiniteMagnitude).size
    }
}
