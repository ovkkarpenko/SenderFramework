//
// Created by Roman Serga on 1/11/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

#if SENDER_FRAMEWORK_USE_GOOGLE_MAPS
@objc(MWUniversalGeocoder)
public class UniversalGeocoder: GoogleGeocoder {}
#else
@objc(MWUniversalGeocoder)
public class UniversalGeocoder: AppleGeocoder {}
#endif
