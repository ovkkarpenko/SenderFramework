//
// Created by Roman Serga on 31/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWMapPointAnnotation)
public class MapPointAnnotation: NSObject, MapAnnotation {
    @objc public private(set) var coordinate: CLLocationCoordinate2D
    @objc public var title: String?
    @objc public var subtitle: String?

    @objc public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
