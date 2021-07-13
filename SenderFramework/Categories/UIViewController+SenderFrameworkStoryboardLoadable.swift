//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {

    @objc public class func loadFromSenderFrameworkStoryboardWith(name: String) -> Self {
        let storyboard = UIStoryboard(fromSenderFrameworkWithName: name)
        let identifier = NSStringFromClass(self)
        return self.loadViewControllerWith(identifier: identifier, fromStoryboard: storyboard)
    }

    private class func loadViewControllerWith<T>(identifier: String, fromStoryboard storyboard: UIStoryboard) -> T {
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
}
