//
// Created by Roman Serga on 18/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class ChatHeaderBuilder {
    let headerWidth: CGFloat

    let sizingHeader: NotificationContainerCell

    let cache: HeaderLayoutCache
    let headerTextCache = MW_PSPDFThreadSafeMutableDictionary()

    init(headerWidth: CGFloat, cache: HeaderLayoutCache) {
        self.cache = cache
        self.headerWidth = headerWidth
        let headerFrame = CGRect(x: 0.0, y: 0.0, width: self.headerWidth, height: 0.0)
        self.sizingHeader = NotificationContainerCell(frame: headerFrame)
        self.sizingHeader.layoutIfNeeded()
    }

    func registerHeadersIn(collectionView: UICollectionView) {
        collectionView.register(NotificationContainerCell.self,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: "chatHeaderView")
    }

    func collectionView(_ collectionView: UICollectionView,
                        reusableViewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: "chatHeaderView",
                                                                     for: indexPath)
        return header
    }

    func customizeHeader(_ header: NotificationContainerCell,
                         at indexPath: IndexPath,
                         withMessagesDay messagesDay: MessagesDay) {
        UIView.performWithoutAnimation { header.layoutIfNeeded() }
        let contentView = NotificationMessageView()
        let maxWidth = header.maxContainerViewWidth
        let headerText = self.headerTextFor(messagesDay: messagesDay)
        if let cachedLayout = self.cache.layoutFor(keyObject: headerText,
                                                   maxWidth: maxWidth) as? NotificationMessageViewLayout {
            _ = contentView.updateWith(text: headerText, maxWidth: maxWidth, layout: cachedLayout)
        } else {
            let layout = contentView.updateWith(text: headerText, maxWidth: maxWidth, layout: nil)
            self.cache.setLayout(layout, forKeyObject: headerText, maxWidth: maxWidth)
        }
        header.setContent(contentView)
        header.containerView.backgroundColor = .clear
        header.backgroundColor = .clear
        UIView.performWithoutAnimation { header.layoutIfNeeded() }
    }

    func sizeOfHeaderWith(messagesDay: MessagesDay, inSection section: Int) -> CGSize {
        let headerText = self.headerTextFor(messagesDay: messagesDay)
        let maxWidth = sizingHeader.maxContainerViewWidth
        if let cachedLayout = self.cache.layoutFor(keyObject: headerText, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = NotificationMessageView.layoutWith(text: headerText, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: headerText, maxWidth: maxWidth)
        let size = sizingHeader.sizeWith(contentSize: layout.size)
        return size
    }

    func headerTextFor(messagesDay: MessagesDay) -> String {
        if let cachedText = self.headerTextCache[messagesDay.date] as? String {
            return cachedText
        }
        let headerText = ParamsFacade.sharedInstance().getDayAndMonth(fromTime: messagesDay.date)
        self.headerTextCache[messagesDay.date] = headerText
        return headerText
    }
}
