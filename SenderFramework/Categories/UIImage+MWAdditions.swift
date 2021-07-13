//
// Created by Roman Serga on 12/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension UIImage {
    @objc public func mw_roundedImageWith(side: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: side, height: side))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let path = UIBezierPath.init(roundedRect: rect, cornerRadius: side)
        UIGraphicsGetCurrentContext()?.addPath(path.cgPath)
        UIGraphicsGetCurrentContext()?.clip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsGetCurrentContext()
        return image
    }
}
