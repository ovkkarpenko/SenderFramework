//
// Created by Roman Serga on 5/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public extension UIView {
    @objc class func mw_loadFromSenderFrameworkNibNamed(_ nibName: String) -> Self {
        guard let senderBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load senderFrameworkResources Bundle")
        }
        return self.loadViewWith(nibName: nibName, bundle: senderBundle)
    }

    private class func loadViewWith<T>(nibName: String, bundle: Bundle) -> T {
        guard let view = bundle.loadNibNamed(nibName, owner: nil)?.first as? T else {
            fatalError("Cannot load view from nib")
        }
        return view
    }
}