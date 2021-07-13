//
// Created by Roman Serga on 1/11/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWAppleGeocoderPlaceMark)
public class AppleGeocoderPlaceMark: NSObject, GeocoderPlaceMark {
    public var location: CLLocation? { return self.applePlaceMark.location }
    public var country: String? { return self.applePlaceMark.country }
    public var postalCode: String? { return self.applePlaceMark.postalCode }
    public var administrativeArea: String? { return self.applePlaceMark.administrativeArea }
    public var locality: String? { return self.applePlaceMark.locality }
    public var subLocality: String? { return self.applePlaceMark.subLocality }
    public var thoroughfare: String? { return self.applePlaceMark.thoroughfare }
    public var formattedAddress: String? {
        guard let addressDictionary = self.applePlaceMark.addressDictionary else { return nil }
        return ABCreateStringWithAddressDictionary(addressDictionary, false)
    }

    fileprivate var applePlaceMark: CLPlacemark

    init(applePlaceMark: CLPlacemark) {
        self.applePlaceMark = applePlaceMark
    }
}

@objc(MWAppleGeocoder)
public class AppleGeocoder: NSObject, Geocoder {
    public func reverseGeocodeLocation(_ location: CLLocation,
                                       completionHandler: @escaping ([GeocoderPlaceMark]?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            let convertedPlacemarks = placemarks?.flatMap { AppleGeocoderPlaceMark(applePlaceMark: $0) }
            completionHandler(convertedPlacemarks, error)
        }
    }
}
