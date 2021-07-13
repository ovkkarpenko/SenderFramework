//
// Created by Roman Serga on 1/11/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#if SENDER_FRAMEWORK_USE_GOOGLE_MAPS

import Foundation
import GoogleMaps

@objc(MWGoogleGeocoderPlaceMark)
public class GoogleGeocoderPlaceMark: NSObject, GeocoderPlaceMark {
    public var location: CLLocation? {
        let coordinate = self.address.coordinate
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    public var country: String? { return self.address.country }
    public var postalCode: String? { return self.address.postalCode }
    public var administrativeArea: String? { return self.address.administrativeArea }
    public var locality: String? { return self.address.locality }
    public var subLocality: String? { return self.address.subLocality }
    public var thoroughfare: String? { return self.address.thoroughfare }
    public var formattedAddress: String? {
        guard let addressLines = self.address.lines else { return nil }
        return addressLines.joined(separator: " ")
    }

    fileprivate var address: GMSAddress

    init(address: GMSAddress) {
        self.address = address
    }
}

@objc(MWGoogleGeocoder)
public class GoogleGeocoder: NSObject, Geocoder {
    public func reverseGeocodeLocation(_ location: CLLocation,
                                       completionHandler: @escaping ([GeocoderPlaceMark]?, Error?) -> Void) {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(location.coordinate) { response, error in
            let convertedPlacemarks = response?.results()?.flatMap { GoogleGeocoderPlaceMark(address: $0) }
            completionHandler(convertedPlacemarks?.reversed(), error)
        }
    }
}

#endif
