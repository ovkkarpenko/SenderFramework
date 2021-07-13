//
//  MWStringExtentions.swift
//  SENDER
//
//  Created by Eugene Gilko on 6/2/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

extension String {
    func hasLenght() -> Bool {
        return self.lenght() > 0
    }
}

extension String {
    func lenght() -> Int {
        return self.characters.count
    }
}

extension String {
    func toBool() -> Bool {
        switch self {
        case "True", "true", "yes", "1", "YES":
            return true
        case "False", "false", "no", "0", "NO":
            return false
        default:
            return false
        }
    }
}

extension String {
    var localized: String {
        return SenderFrameworkLocalizedString(self)
    }
}
