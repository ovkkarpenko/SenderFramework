//
// Created by Roman Serga on 31/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWAppleMapAnnotationViewDelegate)
protocol AppleMapAnnotationViewDelegate: class {
    func appleMapAnnotationViewDidTap(_ annotationView: AppleMapAnnotationView)
}

@objc (MWAppleMapAnnotationView)
public class AppleMapAnnotationView: MKAnnotationView {

    fileprivate var containerViewSize: CGSize = .zero
    fileprivate weak var content: UIView?

    weak var delegate: AppleMapAnnotationViewDelegate?

    let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        return containerView
    }()

    let actionButton: UIButton = {
        let actionButton = UIButton()
        actionButton.backgroundColor = .clear
        return actionButton
    }()

    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.setUp()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
    }

    func setUp() {
        self.addSubview(self.containerView)
        self.insertSubview(self.actionButton, aboveSubview: self.containerView)
        self.actionButton.addTarget(self, action: #selector(actionButtonDidTap(_:)), for: .touchUpInside)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let containerViewX = CGFloat(0.0)
        let containerViewY = CGFloat(0.0)
        let containerViewOrigin = CGPoint(x: containerViewX, y: containerViewY)
        self.containerView.frame = CGRect(origin: containerViewOrigin, size: self.containerViewSize)
        self.actionButton.frame = self.containerView.frame
    }

    func setContent(_ content: UIView?) {
        self.containerView.subviews.forEach { $0.removeFromSuperview() }
        self.content = content
        if let content = content { self.containerView.addSubview(content) }
        self.changeSizeWithContent(content)
    }

    func changeSizeWithContent(_ content: UIView?) {
        self.containerViewSize = content?.frame.size ?? .zero
        let newSize = self.sizeWith(contentSize: self.containerViewSize)
        self.frame = CGRect(origin: self.frame.origin, size: newSize)
        self.setNeedsLayout()
    }

    func sizeWith(contentSize: CGSize) -> CGSize {
        /*
            Setting height as doubled height of content, in order to position content's bottom
            in center of AnnotationView. Without doing so, content will look like it's positioned lower then
            the annotation actually is.
        */
        return CGSize(width: contentSize.width, height: contentSize.height * 2)
    }

    @objc func actionButtonDidTap(_ actionButton: UIButton) {
        self.delegate?.appleMapAnnotationViewDidTap(self)
    }
}

extension MKPointAnnotation {
    convenience init(annotation: MapAnnotation) {
        self.init()
        self.coordinate = annotation.coordinate
        self.title = annotation.title
        self.subtitle = annotation.subtitle
    }
}

extension MKCoordinateSpan {
    init(span: MapCoordinateSpan) {
        self.init(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
    }
}

extension MapCoordinateSpan {
    convenience init(span: MKCoordinateSpan) {
        self.init(latitudeDelta: span.latitudeDelta, longitudeDelta: span.longitudeDelta)
    }
}

extension MKCoordinateRegion {
    init(region: MapRegion) {
        let span = MKCoordinateSpan(span: region.span)
        self.init(center: region.center, span: span)
    }
}

extension MapRegion {
    convenience init(region: MKCoordinateRegion) {
        let span = MapCoordinateSpan(span: region.span)
        self.init(center: region.center, span: span)
    }
}

@objc (MWAppleMapView)
public class AppleMapView: UIView, MapView {
    fileprivate let containerAnnotationIdentifier = "ContainerAnnotationView"

    fileprivate let mapView = MKMapView()
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!

    fileprivate var identifiersStore = [MKPointAnnotation: (MapAnnotation, String)]()
    fileprivate var viewsCache = [String: [UIView & MapAnnotationView]]()

    public weak var delegate: MapViewDelegate?

    public var isUserLocationVisible: Bool {
        get { return self.mapView.showsUserLocation }
        set { self.mapView.showsUserLocation = newValue }
    }

    public var areBuildingsVisible: Bool {
        get { return self.mapView.showsBuildings }
        set { self.mapView.showsBuildings = newValue }
    }

    public var isTrafficVisible: Bool {
        get { return self.mapView.showsTraffic }
        set { self.mapView.showsTraffic = newValue }
    }

    public var isZoomEnabled: Bool {
        get { return self.mapView.isZoomEnabled }
        set { self.mapView.isZoomEnabled = newValue }
    }

    public var isScrollEnabled: Bool {
        get { return self.mapView.isScrollEnabled }
        set { self.mapView.isScrollEnabled = newValue }
    }

    public var isRotationEnabled: Bool {
        get { return self.mapView.isRotateEnabled }
        set { self.mapView.isRotateEnabled = newValue }
    }

    public var selectedAnnotation: MapAnnotation? {
        get {
            guard let selectedAppleAnnotation = self.mapView.selectedAnnotations.first as? MKPointAnnotation else {
                return nil
            }
            return self.annotationFor(appleAnnotation: selectedAppleAnnotation)
        }
        set {
            guard let newValue = newValue,
                  let appleAnnotation = self.appleAnnotationFor(annotation: newValue) else {
                self.mapView.selectedAnnotations = []
                return
            }
            self.mapView.selectedAnnotations = [appleAnnotation]
        }
    }

    public var annotations: [MapAnnotation] {
        return self.mapView.annotations.flatMap({ annotation in
            guard let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
            return self.annotationFor(appleAnnotation: pointAnnotation)
        })
    }

    public var region: MapRegion {
        get {
            return MapRegion(region: self.mapView.region)
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

    func setUp() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.tapGestureRecognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapGestureRecognizer)

        self.mapView.delegate = self
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.mapView)
        self.mw_pinSubview(self.mapView)
    }

    func annotationFor(appleAnnotation: MKPointAnnotation) -> MapAnnotation? {
        return self.identifiersStore[appleAnnotation]?.0
    }

    func appleAnnotationFor(annotation: MapAnnotation) -> MKPointAnnotation? {
        return self.identifiersStore.first(where: { $0.1.0 === annotation })?.0
    }

    public func addAnnotation(_ annotation: MapAnnotation, withIdentifier identifier: String) {
        let pointAnnotation = MKPointAnnotation(annotation: annotation)
        self.identifiersStore[pointAnnotation] = (annotation, identifier)
        self.mapView.addAnnotation(pointAnnotation)
    }

    public func removeAnnotation(_ annotation: MapAnnotation) {
        guard let pointAnnotation = self.appleAnnotationFor(annotation: annotation) else { return }
        self.identifiersStore[pointAnnotation] = nil
        self.mapView.removeAnnotation(pointAnnotation)
    }

    public func convertPointToCoordinates(_  point: CGPoint) -> CLLocationCoordinate2D {
        return self.mapView.convert(point, toCoordinateFrom: self)
    }

    public func invalidateCache() {
        self.viewsCache.removeAll()
    }

    fileprivate func contentViewWith(annotation: MapAnnotation, identifier: String) -> (UIView & MapAnnotationView)? {
        let annotationView: (UIView & MapAnnotationView)?
        if let cachedView = self.viewsCache[identifier]?.first(where: { $0.superview == nil }) {
            annotationView = cachedView
        } else {
            annotationView = self.delegate?.mapView(self, viewForAnnotation: annotation, withIdentifier: identifier)
            if let annotationViewUnwrapped = annotationView {
                var cachedViewsArray = self.viewsCache[identifier] ?? []
                cachedViewsArray.append(annotationViewUnwrapped)
                self.viewsCache[identifier] = cachedViewsArray
            }
        }
        annotationView?.updateWith(annotation: annotation)
        return annotationView
    }

    public func setRegion(_ region: MapRegion, animated: Bool) {
        let appleRegion = MKCoordinateRegion(region: region)
        self.mapView.setRegion(appleRegion, animated: animated)
    }

    public func fitRegion(_ region: MapRegion, animated: Bool) {
        let appleRegion = MKCoordinateRegion(region: region)
        let fixedAppleRegion = self.mapView.regionThatFits(appleRegion)
        self.mapView.setRegion(fixedAppleRegion, animated: animated)
    }

    @objc fileprivate func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        let coordinate = self.convertPointToCoordinates(point)
        self.delegate?.mapView(self, didTapAtCoordinate: coordinate)
    }
}

extension AppleMapView: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let pointAnnotation = annotation as? MKPointAnnotation,
              let (mapAnnotation, viewIdentifier) = self.identifiersStore[pointAnnotation],
              let content = self.contentViewWith(annotation: mapAnnotation,
                                                 identifier: viewIdentifier) else { return nil }

        let containerAnnotationView: AppleMapAnnotationView
        let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: self.containerAnnotationIdentifier)
        if let existingContainerView = existingView as? AppleMapAnnotationView {
            containerAnnotationView = existingContainerView
        } else {
            containerAnnotationView = AppleMapAnnotationView(annotation: annotation,
                                                             reuseIdentifier: self.containerAnnotationIdentifier)
        }
        containerAnnotationView.delegate = self
        containerAnnotationView.setContent(content)
        return containerAnnotationView
    }
}

extension AppleMapView: AppleMapAnnotationViewDelegate {
    func appleMapAnnotationViewDidTap(_ annotationView: AppleMapAnnotationView) {
        guard let appleAnnotation = annotationView.annotation as? MKPointAnnotation,
              let annotation = self.annotationFor(appleAnnotation: appleAnnotation) else { return }
        self.delegate?.mapView(self, didTapAtViewForAnnotation: annotation)
    }
}
