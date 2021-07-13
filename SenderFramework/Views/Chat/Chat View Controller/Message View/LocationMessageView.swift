//
// Created by Roman Serga on 8/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class LocationMessageView: MediaMessageView {

    let mapView: UniversalMapView = {
        let mapView = UniversalMapView()
        mapView.isUserInteractionEnabled = false
        return mapView
    }()

    func updateWith(locationMessage: LocationMessageViewModel,
                    maxWidth: CGFloat,
                    layout: MediaMessageViewLayout? = nil) -> MediaMessageViewLayout {
        let layout = super.updateWith(message: locationMessage, maxWidth: maxWidth, layout: layout)
        self.setContent(self.mapView)
        let coordinates = CLLocationCoordinate2DMake(locationMessage.latitude,
                                                     locationMessage.longitude)
        let span = MapCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MapRegion(center: coordinates, span: span)
        //If Google Maps view is used, it won't set region without DispatchQueue.async
        DispatchQueue.main.async { self.mapView.setRegion(region, animated: false) }
        let locationFromMessage = MapPointAnnotation(coordinate: coordinates)
        self.mapView.addAnnotation(locationFromMessage, withIdentifier: "Annotation")
        self.isBorderVisible = false
        return layout
    }
}
