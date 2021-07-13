//
// Created by Roman Serga on 15/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

    /*
        sets sourceView, sourceRect and permittedArrowDirections in order to be easily presented on iPad
    */
    @objc public func mw_safePresentIn(viewController: UIViewController,
                                 animated flag: Bool,
                                 completion: (() -> Void)? = nil) {
        self.popoverPresentationController?.sourceView = viewController.view
        let sourceRect = CGRect(x: viewController.view.bounds.size.width / 2.0 - 0.5,
                                y: viewController.view.bounds.size.height / 2.0 - 0.5,
                                width: 1.0,
                                height: 1.0)
        self.popoverPresentationController?.sourceRect = sourceRect
        self.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        viewController.present(self, animated: flag, completion: completion)
    }
}
