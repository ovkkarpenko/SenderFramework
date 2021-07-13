//
// Created by Roman Serga on 11/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol LayoutCacheKeyObject {
    var objectID: String { get }
}

class LayoutCache<KeyObjectType, LayoutType> where KeyObjectType: LayoutCacheKeyObject {
    private var cachedLayouts = MW_PSPDFThreadSafeMutableDictionary()

    fileprivate func keyWith(keyObject: KeyObjectType, maxWidth: CGFloat) -> String {
        return keyObject.objectID + "_\(maxWidth)"
    }

    func layoutFor(keyObject: KeyObjectType, maxWidth: CGFloat) -> LayoutType? {
        let key = self.keyWith(keyObject: keyObject, maxWidth: maxWidth)
        return self.cachedLayouts[key] as? LayoutType
    }

    func setLayout(_ layout: LayoutType,
                   forKeyObject keyObject: KeyObjectType,
                   maxWidth: CGFloat) {
        let key = self.keyWith(keyObject: keyObject, maxWidth: maxWidth)
        self.cachedLayouts[key] = layout
    }

    func invalidate() {
        self.cachedLayouts = MW_PSPDFThreadSafeMutableDictionary()
    }

    func invalidateCacheFor(keyObject: KeyObjectType) {
        let keysToRemove = self.cachedLayouts.allKeys.filter { ($0 as? String)?.hasPrefix(keyObject.objectID) ?? false }
        keysToRemove.forEach { self.cachedLayouts[$0] = nil }
    }
}

extension AbstractMessageViewModel: LayoutCacheKeyObject {
    var objectID: String { return self.messageID }
}

class MessagesLayoutCache: LayoutCache<AbstractMessageViewModel, BaseMessageLayout>  {

}
