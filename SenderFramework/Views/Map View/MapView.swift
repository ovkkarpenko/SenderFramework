//
// Created by Roman Serga on 31/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWMapAnnotation)
public protocol MapAnnotation {
    var coordinate: CLLocationCoordinate2D { get }
    var title: String? { get }
    var subtitle: String? { get }
}

@objc(MWMapAnnotationView)
public protocol MapAnnotationView {
    var annotation: MapAnnotation { get }
    func updateWith(annotation: MapAnnotation)
}

@objc(MWMapCoordinateSpan)
public class MapCoordinateSpan: NSObject {
    @objc public var latitudeDelta: CLLocationDegrees
    @objc public var longitudeDelta: CLLocationDegrees

    @objc public init(latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

@objc(MWMapRegion)
public class MapRegion: NSObject {
    @objc public var center: CLLocationCoordinate2D
    @objc public var span: MapCoordinateSpan

    @objc public init(center: CLLocationCoordinate2D, span: MapCoordinateSpan) {
        self.center = center
        self.span = span
    }
}

@objc(MWMapView)
public protocol MapView {
    var isUserLocationVisible: Bool { get set }
    var areBuildingsVisible: Bool { get set }
    var isTrafficVisible: Bool { get set }
    var isZoomEnabled: Bool { get set }
    var isScrollEnabled: Bool { get set }
    var isRotationEnabled: Bool { get set }
    var selectedAnnotation: MapAnnotation? { get set }
    var annotations: [MapAnnotation] { get }

    weak var delegate: MapViewDelegate? { get set }

    var region: MapRegion { get set }

    func addAnnotation(_ annotation: MapAnnotation, withIdentifier identifier: String)
    func removeAnnotation(_ annotation: MapAnnotation)

    func convertPointToCoordinates(_ point: CGPoint) -> CLLocationCoordinate2D

    /*
        View must invalidate cached annotation views, if uses caching
     */
    func invalidateCache()

    func setRegion(_ region: MapRegion, animated: Bool)

    /*
        Sets region, adjusted to fit into map view's frame
     */
    func fitRegion(_ region: MapRegion, animated: Bool)
}

@objc(MWMapViewDelegate)
public protocol MapViewDelegate: class {
    func mapView(_ mapView: MapView,
                 viewForAnnotation annotation: MapAnnotation,
                 withIdentifier identifier: String) -> (UIView & MapAnnotationView)

    func mapView(_ mapView: MapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: MapView, didTapAtViewForAnnotation: MapAnnotation)
}

@objc(MWGeocoderPlaceMark)
public protocol GeocoderPlaceMark {
    var location: CLLocation? { get }
    var country: String? { get }
    var postalCode: String? { get }
    var administrativeArea: String? { get }
    var locality: String? { get }
    var subLocality: String? { get }
    var thoroughfare: String? { get }
    var formattedAddress: String? { get }
}

@objc(MWGeocoder)
public protocol Geocoder {
    func reverseGeocodeLocation(_ location: CLLocation,
                                completionHandler: @escaping ([GeocoderPlaceMark]?, Error?) -> Void)
}
