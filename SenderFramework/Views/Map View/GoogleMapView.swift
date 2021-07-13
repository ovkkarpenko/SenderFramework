//
// Created by Roman Serga on 1/11/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#if SENDER_FRAMEWORK_USE_GOOGLE_MAPS

import Foundation
import GoogleMaps

extension MapPointAnnotation {
    convenience init(marker: GMSMarker) {
        self.init(coordinate: marker.position)
        self.title = marker.title
    }
}

extension GMSMarker {
    convenience init(annotation: MapAnnotation) {
        self.init(position: annotation.coordinate)
        self.title = annotation.title
    }
}

extension GMSCoordinateBounds {
    convenience init(region: MapRegion) {
        let center = region.center
        let span = region.span
        let upperLeft = CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2,
                                               longitude: center.longitude - span.longitudeDelta / 2)
        let bottomRight = CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2,
                                                 longitude: center.longitude + span.longitudeDelta / 2)
        self.init(coordinate: upperLeft, coordinate: bottomRight)
    }
}

extension MapRegion {
    convenience init(bounds: GMSCoordinateBounds) {
        let latitudeDelta = bounds.northEast.latitude - bounds.southWest.latitude
        let longitudeDelta = bounds.northEast.longitude - bounds.southWest.longitude
        let span = MapCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let center = CLLocationCoordinate2D(latitude: bounds.northEast.latitude + latitudeDelta / 2,
                                            longitude: bounds.northEast.longitude + longitudeDelta / 2)
        self.init(center: center, span: span)
    }
}

@objc(MWGoogleMapView)
public class GoogleMapView: UIView, MapView {

    let mapView = GMSMapView()

    fileprivate var identifiersStore = [GMSMarker: (MapAnnotation, String)]()
    fileprivate var viewsCache = [String: [UIView & MapAnnotationView]]()
    fileprivate var mapViewEventHandler = GoogleMapViewDelegate()
    public weak var delegate: MapViewDelegate?

    public var isUserLocationVisible: Bool {
        get { return self.mapView.isMyLocationEnabled }
        set { self.mapView.isMyLocationEnabled = newValue }
    }

    public var areBuildingsVisible: Bool {
        get { return self.mapView.isBuildingsEnabled }
        set { self.mapView.isBuildingsEnabled = newValue }
    }

    public var isTrafficVisible: Bool {
        get { return self.mapView.isTrafficEnabled }
        set { self.mapView.isTrafficEnabled = newValue }
    }

    public var isZoomEnabled: Bool {
        get { return self.mapView.settings.zoomGestures }
        set { self.mapView.settings.zoomGestures = newValue }
    }

    public var isScrollEnabled: Bool {
        get { return self.mapView.settings.scrollGestures }
        set { self.mapView.settings.scrollGestures = newValue }
    }

    public var isRotationEnabled: Bool {
        get { return self.mapView.settings.rotateGestures }
        set { self.mapView.settings.rotateGestures = newValue }
    }

    public var selectedAnnotation: MapAnnotation? {
        get {
            guard let selectedMarker = self.mapView.selectedMarker else { return nil }
            return MapPointAnnotation(marker: selectedMarker)
        }
        set {
            guard let newValue = newValue,
                  let marker = self.markerFor(annotation: newValue) else {
                self.mapView.selectedMarker = nil
                return
            }
            self.mapView.selectedMarker = marker
        }
    }

    public var annotations: [MapAnnotation] {
        return self.identifiersStore.values.map { $0.0 }
    }

    public var region: MapRegion {
        get {
            let googleRegion = self.mapView.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(region: googleRegion)
            return MapRegion(bounds: bounds)
        }
        set {
            self.setRegion(region, animated: false)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    fileprivate func setUp() {
        self.mapView.delegate = self.mapViewEventHandler
        self.mapViewEventHandler.eventHandler = self
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.mapView)
        self.mw_pinSubview(self.mapView)
    }

    fileprivate func annotationFor(marker: GMSMarker) -> MapAnnotation? {
        return self.identifiersStore[marker]?.0
    }

    fileprivate func markerFor(annotation: MapAnnotation) -> GMSMarker? {
        return self.identifiersStore.first(where: { $0.1.0 === annotation })?.0
    }

    public func addAnnotation(_ annotation: MapAnnotation, withIdentifier identifier: String) {
        let marker = GMSMarker(annotation: annotation)
        self.identifiersStore[marker] = (annotation, identifier)
        marker.iconView = self.contentViewWith(annotation: annotation, identifier: identifier)
        marker.map = self.mapView
    }

    public func removeAnnotation(_ annotation: MapAnnotation) {
        guard let marker = self.markerFor(annotation: annotation) else { return }
        self.identifiersStore[marker] = nil
        marker.map = nil
    }

    public func convertPointToCoordinates(_  point: CGPoint) -> CLLocationCoordinate2D {
        return self.mapView.projection.coordinate(for: point)
    }

    public func invalidateCache() { }

    fileprivate func contentViewWith(annotation: MapAnnotation, identifier: String) -> (UIView & MapAnnotationView)? {
        let annotationView = self.delegate?.mapView(self, viewForAnnotation: annotation, withIdentifier: identifier)
        annotationView?.updateWith(annotation: annotation)
        return annotationView
    }

    public func setRegion(_ region: MapRegion, animated: Bool) {
        let bounds = GMSCoordinateBounds(region: region)
        guard let camera = self.mapView.camera(for: bounds, insets:.zero) else { return }
        if animated {
            self.mapView.animate(to: camera)
        } else {
            self.mapView.camera = camera
        }
    }

    public func fitRegion(_ region: MapRegion, animated: Bool) {
        let bounds = GMSCoordinateBounds(region: region)
        let cameraUpdate = GMSCameraUpdate.fit(bounds)
        self.mapView.animate(with: cameraUpdate)
    }
}

/*
    There are problems with linking GoogleMaps SDK to Swift projects.
    GoogleMaps SDK has some problems with defining modules and it's modules are invisible from *-Swift.h
    https://github.com/googlemaps/google-maps-ios-utils/issues/19
    https://github.com/googlemaps/google-maps-ios-utils/pull/20
    So, currently if we link GoogleMaps SDK, we add -fno-modules to other c flags.

    Because of this, we cannot use GoogleMaps classes in public swift classes, because they are imported to
    *-Swift.h file, and GoogleMaps SDK modules are invisible from here.

    We create fileprivate GoogleMapViewDelegate class in order remove public conformance to GMSMapViewDelegate
    protocol from public GoogleMapView. And in such way, remove reference to GoogleMaps SDK from *-Swift.h file.
*/

extension GoogleMapView {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.delegate?.mapView(self, didTapAtCoordinate: coordinate)
    }

    /*
        Returning empty view in order to disable showing info view for selected marker
     */
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        return UIView()
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let annotation = self.annotationFor(marker: marker) else { return true }
        self.delegate?.mapView(self, didTapAtViewForAnnotation: annotation)
        return true
    }
}

fileprivate protocol GoogleMapViewDelegateEventHandler: class {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView?
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
}

fileprivate class GoogleMapViewDelegate: NSObject, GMSMapViewDelegate {
    weak var eventHandler: GoogleMapView?

    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.eventHandler?.mapView(mapView, didTapAt: coordinate)
    }

    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        return self.eventHandler?.mapView(mapView, markerInfoWindow: marker)
    }

    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let delegate = self.eventHandler else { return false }
        return delegate.mapView(mapView, didTap: marker)
    }
}

#endif
