//
// Created by Roman Serga on 31/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

#if SENDER_FRAMEWORK_USE_GOOGLE_MAPS
@objc(MWUniversalMapView)
public class UniversalMapView: GoogleMapView {}
#else
@objc(MWUniversalMapView)
public class UniversalMapView: AppleMapView {}
#endif
