//
// Created by Roman Serga on 12/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension String: LayoutCacheKeyObject {
    var objectID: String { return self }
}

class HeaderLayoutCache: LayoutCache<String, BaseMessageLayout> {}
