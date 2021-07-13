//
// Created by Roman Serga on 10/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ChatCollectionViewLayoutDelegate: class {
    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  heightForHeaderInSection section: Int) -> CGFloat?

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  heightForFooterInSection section: Int) -> CGFloat?

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  prefetchSizeForItemAtIndexPath indexPath: IndexPath)

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  spaceBetweenItemsInSection section: Int) -> CGFloat

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  insetsForSection section: Int) -> UIEdgeInsets
}

class ChatCollectionViewLayoutSection {
    var minY: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    var sectionInset: UIEdgeInsets = .zero
    var contentWidth: CGFloat = 0.0
    var itemsAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    var headerAttributes: UICollectionViewLayoutAttributes?
    var footerAttributes: UICollectionViewLayoutAttributes?

    var maxSectionRect: CGRect {
        let x = self.sectionInset.left
        let y = self.minY
        let width = self.contentWidth - (sectionInset.left + sectionInset.right)
        let height = self.maxY - self.minY
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

class ChatCollectionViewLayoutStorage {
    var sections: [Int: ChatCollectionViewLayoutSection]

    init(sections: [Int: ChatCollectionViewLayoutSection] = [:]) {
        self.sections = sections
    }
}

class ChatCollectionViewLayout: UICollectionViewLayout {

    var invalidateCacheOnPrepare: Bool = false
    var sectionHeadersPinToVisibleBounds: Bool = false
    var layoutStorage = ChatCollectionViewLayoutStorage()
    var topVisibleIndexPath = IndexPath(item: 0, section: 0)

    var contentWidth: CGFloat {
        let insets = self.collectionView!.mw_contentInsetWithAdjustments
        let collectionViewBounds = self.collectionView!.bounds
        return collectionViewBounds.width - (insets.left + insets.right)
    }

    weak var delegate: ChatCollectionViewLayoutDelegate?

    override var collectionViewContentSize: CGSize {
        let lastSectionIndex = (self.collectionView?.numberOfSections ?? 0) - 1
        return CGSize(width: self.contentWidth, height: self.layoutStorage.sections[lastSectionIndex]?.maxY ?? 0)
    }

    override func prepare() {
        super.prepare()
        guard self.invalidateCacheOnPrepare else { return }
        self.invalidateCacheOnPrepare = false
        self.calculateCachedAttributes()
        self.calculateInvisibleItemsAttributes()
    }

    func calculateCachedAttributes() {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return }
        let startSection = self.topVisibleIndexPath.section
        let startItem = self.topVisibleIndexPath.item
        guard startSection < collectionView.numberOfSections,
              startItem < collectionView.numberOfItems(inSection: startSection) else {
            self.layoutStorage = ChatCollectionViewLayoutStorage()
            return
        }

        let newLayoutStorage = ChatCollectionViewLayoutStorage()

        var yOffset: CGFloat = 0.0
        for section in 0..<(collectionView.numberOfSections) {
            let sectionInsets = self.sectionInsetsFor(section: section)
            yOffset += sectionInsets.top

            let layoutSection = ChatCollectionViewLayoutSection()
            layoutSection.minY = yOffset
            layoutSection.sectionInset = sectionInsets
            layoutSection.contentWidth = self.contentWidth

            let (headerHeight, headerAttributes) = self.headerAttributesFor(section: section,
                                                                            collectionView: collectionView,
                                                                            delegate: delegate,
                                                                            startY: yOffset,
                                                                            sectionInsets: sectionInsets)
            yOffset += headerHeight

            let (itemsHeight, itemsAttributes) = self.itemsAttributesFor(section: section,
                                                                         collectionView: collectionView,
                                                                         delegate: delegate,
                                                                         startY: yOffset,
                                                                         sectionInsets: sectionInsets)

            yOffset += itemsHeight

            let (footerHeight, footerAttributes) =  self.footerAttributesFor(section: section,
                                                                             collectionView: collectionView,
                                                                             delegate: delegate,
                                                                             startY: yOffset,
                                                                             sectionInsets: sectionInsets)
            yOffset += footerHeight

            layoutSection.headerAttributes = headerAttributes
            layoutSection.footerAttributes = footerAttributes
            layoutSection.itemsAttributes = itemsAttributes
            layoutSection.maxY = yOffset

            newLayoutStorage.sections[section] = layoutSection

            yOffset += sectionInsets.bottom
        }
        self.layoutStorage = newLayoutStorage
    }

    func sectionInsetsFor(section: Int) -> UIEdgeInsets {
        let isSectionVisible = self.isSectionVisible(section)
        let sectionInsets: UIEdgeInsets
        if isSectionVisible,
           let delegateInsets = self.delegate?.chatCollectionViewLayout(self, insetsForSection: section) {
            sectionInsets = delegateInsets
        } else {
            sectionInsets = .zero
        }
        return sectionInsets
    }

    func headerAttributesFor(section: Int,
                             collectionView: UICollectionView,
                             delegate: ChatCollectionViewLayoutDelegate,
                             startY: CGFloat,
                             sectionInsets: UIEdgeInsets) -> (CGFloat, UICollectionViewLayoutAttributes?) {
        guard section < collectionView.numberOfSections,
              collectionView.numberOfItems(inSection: section) > 0,
              let delegateHeaderHeight = delegate.chatCollectionViewLayout(self,
                                                                           heightForHeaderInSection: section) else {
            return (0.0, nil)
        }
        var yChange: CGFloat = 0.0
        let sectionWidth = self.contentWidth - (sectionInsets.left + sectionInsets.right)
        let isSectionHeaderVisible = self.isSectionHeaderVisible(section)
        let headerHeight = isSectionHeaderVisible ? delegateHeaderHeight : CGFloat(0.0)
        let headerOrigin = CGPoint(x: sectionInsets.left, y: startY)
        let headerSize = CGSize(width: sectionWidth, height: headerHeight)
        let headerFrame = CGRect(origin: headerOrigin, size: headerSize)
        let headerKind = UICollectionElementKindSectionHeader
        let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: headerKind,
                                                                with: IndexPath(item: 0, section: section))
        self.fixZIndexFor(attributes: headerAttributes)
        headerAttributes.isHidden = !isSectionHeaderVisible
        headerAttributes.frame = headerFrame
        yChange += headerHeight
        if isSectionHeaderVisible {
            yChange += delegate.chatCollectionViewLayout(self, spaceBetweenItemsInSection: section)
        }
        return (yChange, headerAttributes)
    }

    func footerAttributesFor(section: Int,
                             collectionView: UICollectionView,
                             delegate: ChatCollectionViewLayoutDelegate,
                             startY: CGFloat,
                             sectionInsets: UIEdgeInsets) -> (CGFloat, UICollectionViewLayoutAttributes?) {
        guard collectionView.numberOfItems(inSection: section) > 0,
              let delegateFooterHeight = delegate.chatCollectionViewLayout(self,
                                                                           heightForFooterInSection: section) else {
            return (0.0, nil)
        }
        var yChange: CGFloat = 0.0
        let sectionWidth = self.contentWidth - (sectionInsets.left + sectionInsets.right)
        let isSectionFooterVisible = self.isSectionFooterVisible(section)
        let footerHeight = isSectionFooterVisible ? delegateFooterHeight : CGFloat(0.0)
        let footerOrigin = CGPoint(x: sectionInsets.left, y: startY)
        let footerSize = CGSize(width: sectionWidth, height: footerHeight)
        let footerFrame = CGRect(origin: footerOrigin, size: footerSize)
        let footerKind = UICollectionElementKindSectionFooter
        let footerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: footerKind,
                                                                with: IndexPath(item: 0, section: section))
        self.fixZIndexFor(attributes: footerAttributes)
        footerAttributes.isHidden = !isSectionFooterVisible
        footerAttributes.frame = footerFrame
        yChange += footerHeight
        return (yChange, footerAttributes)
    }

    func itemsAttributesFor(section: Int,
                            collectionView: UICollectionView,
                            delegate: ChatCollectionViewLayoutDelegate,
                            startY: CGFloat,
                            sectionInsets: UIEdgeInsets) -> (CGFloat, [IndexPath: UICollectionViewLayoutAttributes]) {
        var yChange: CGFloat = 0.0
        let sectionWidth = self.contentWidth - (sectionInsets.left + sectionInsets.right)
        let numberOfItemsInSection = collectionView.numberOfItems(inSection: section)
        var itemsAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
        for item in 0..<numberOfItemsInSection {
            let indexPath = IndexPath(item: item, section: section)
            let isItemVisible = self.isItemVisibleAt(indexPath: indexPath)
            let itemSize: CGSize
            if isItemVisible {
                itemSize = delegate.chatCollectionViewLayout(self, sizeForItemAtIndexPath: indexPath)
            } else {
                itemSize = .zero
            }
            let xOffset = ceil((sectionWidth - itemSize.width) / 2)
            let itemOrigin = CGPoint(x: xOffset, y: startY + yChange)
            let itemFrame = CGRect(origin: itemOrigin, size: itemSize)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            self.fixZIndexFor(attributes: attributes)
            attributes.isHidden = !isItemVisible
            attributes.frame = itemFrame
            itemsAttributes[indexPath] = attributes
            yChange += itemSize.height

            if isItemVisible {
                yChange += delegate.chatCollectionViewLayout(self, spaceBetweenItemsInSection: section)
            }
        }
        return (yChange, itemsAttributes)
    }

    func fixZIndexFor(attributes: UICollectionViewLayoutAttributes) {
        let itemZIndex = 750
        let headerZIndex = self.sectionHeadersPinToVisibleBounds ? 1000 : itemZIndex
        let footerZIndex = itemZIndex
        guard let elementKind = attributes.representedElementKind else { attributes.zIndex = itemZIndex; return }
        switch elementKind {
        case UICollectionElementKindSectionHeader: attributes.zIndex = headerZIndex
        case UICollectionElementKindSectionFooter: attributes.zIndex = footerZIndex
        default: attributes.zIndex = itemZIndex
        }
    }

    func isSectionVisible(_ section: Int) -> Bool {
        return section >= self.topVisibleIndexPath.section
    }

    func isSectionHeaderVisible(_ section: Int) -> Bool {
        let isSectionHeaderVisible: Bool
        if self.sectionHeadersPinToVisibleBounds {
            isSectionHeaderVisible = self.isSectionVisible(section)
        } else {
            isSectionHeaderVisible = section > self.topVisibleIndexPath.section ||
                    (section == self.topVisibleIndexPath.section && self.topVisibleIndexPath.item == 0)
        }
        return isSectionHeaderVisible
    }

    func isSectionFooterVisible(_ section: Int) -> Bool {
        return self.isSectionVisible(section)
    }

    func isItemVisibleAt(indexPath: IndexPath) -> Bool {
        return indexPath >= self.topVisibleIndexPath
    }

    func calculateInvisibleItemsAttributes() {
        guard let collectionView = self.collectionView,
              let delegate = self.delegate else { return }

        let startSection: Int
        let startItem: Int
        if self.topVisibleIndexPath.item == 0 {
            startSection = self.topVisibleIndexPath.section - 1
            guard startSection >= 0 else { return }
            startItem = self.collectionView!.numberOfItems(inSection: startSection) - 1
        } else {
            startSection = self.topVisibleIndexPath.section
            startItem = self.topVisibleIndexPath.item - 1
        }

        guard startItem >= 0 else { return }

        for section in stride(from:(startSection), to:-1, by:-1) {
            let isStartSection = (section == startSection)
            let firstIndexPath = isStartSection ? startItem : collectionView.numberOfItems(inSection: section) - 1

            for item in stride(from:(firstIndexPath), to:-1, by:-1) {
                let indexPath = IndexPath(item: item, section: section)
                delegate.chatCollectionViewLayout(self, prefetchSizeForItemAtIndexPath: indexPath)
            }
        }
    }

    func sectionsVisibleIn(rect: CGRect) -> [(Int, ChatCollectionViewLayoutSection)] {
        return self.layoutStorage.sections.filter { (_, section) -> Bool in section.maxSectionRect.intersects(rect) }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let sectionsInRect = self.sectionsVisibleIn(rect: rect)

        let itemsAttributes = sectionsInRect.map({$0.1}).flatMap {
            $0.itemsAttributes.values.filter {$0.frame.intersects(rect) && !$0.isHidden}
        } as [UICollectionViewLayoutAttributes]

        let supplementaryAttributes = sectionsInRect.flatMap { sectionIndex, _ -> [UICollectionViewLayoutAttributes] in
            let indexPath = IndexPath(item: 0, section: sectionIndex)
            let headerKind = UICollectionElementKindSectionHeader
            let headerAttributes = self.layoutAttributesForSupplementaryView(ofKind: headerKind, at: indexPath)
            let footerKind = UICollectionElementKindSectionFooter
            let footerAttributes = self.layoutAttributesForSupplementaryView(ofKind: footerKind, at: indexPath)
            return [headerAttributes, footerAttributes].flatMap({$0}).filter { $0.frame.intersects(rect) }
        }

        return itemsAttributes + supplementaryAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let section = self.layoutStorage.sections[indexPath.section],
              indexPath.item >= 0 && indexPath.item < section.itemsAttributes.count else { return nil }
        return section.itemsAttributes[indexPath]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let section = self.layoutStorage.sections[indexPath.section] else { return nil }
        var layoutAttributes: UICollectionViewLayoutAttributes?
        if elementKind == UICollectionElementKindSectionHeader {
            if let cachedAttributes = section.headerAttributes {
                layoutAttributes = cachedAttributes
            } else {
                if let collectionView = self.collectionView, let delegate = self.delegate {
                    let sectionInsets = self.sectionInsetsFor(section: indexPath.section)
                    let (_, headerAttributes) = self.headerAttributesFor(section: indexPath.section,
                                                                         collectionView: collectionView,
                                                                         delegate: delegate,
                                                                         startY: section.minY,
                                                                         sectionInsets: sectionInsets)
                    section.headerAttributes = headerAttributes
                    layoutAttributes = headerAttributes
                } else {
                    layoutAttributes = nil
                }
            }
        } else if elementKind == UICollectionElementKindSectionFooter {
            layoutAttributes = section.footerAttributes
        } else {
            layoutAttributes =  nil
        }

        guard elementKind == UICollectionElementKindSectionHeader,
              self.sectionHeadersPinToVisibleBounds,
              let collectionView = self.collectionView,
              let headerAttributes = layoutAttributes else { return layoutAttributes }

        let contentOffset = collectionView.contentOffset
        let topInset = collectionView.mw_contentInsetWithAdjustments.top

        let minHeaderY = section.minY
        let maxHeaderY = section.maxY

        var headerFrame = headerAttributes.frame
        let topContentOffsetY = contentOffset.y + topInset
        if headerFrame.origin.y < topContentOffsetY,
           topContentOffsetY >= minHeaderY,
           topContentOffsetY <= maxHeaderY {
            headerFrame.origin.y = topContentOffsetY
            if headerFrame.origin.y + headerFrame.height > maxHeaderY {
                headerFrame.origin.y = maxHeaderY - headerFrame.height
            } else if headerFrame.origin.y < minHeaderY {
                headerFrame.origin.y = minHeaderY
            }
        }

        headerAttributes.frame = headerFrame

        return headerAttributes

    }

    override func invalidateLayout() {
        self.invalidateCacheOnPrepare = true
        super.invalidateLayout()
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateEverything ||
           context.invalidateDataSourceCounts ||
           context.invalidatedItemIndexPaths != nil {
            self.invalidateCacheOnPrepare = true
        }
        super.invalidateLayout(with: context)
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let invalidationContext = super.invalidationContext(forBoundsChange: newBounds)
        guard let oldBounds = self.collectionView?.bounds else { return invalidationContext }
        if self.sectionHeadersPinToVisibleBounds {
            if oldBounds.size == newBounds.size && oldBounds.origin != newBounds.origin {
                let sectionsInOldBounds = self.sectionsVisibleIn(rect: oldBounds)
                let sectionsInNewBounds = self.sectionsVisibleIn(rect: newBounds)
                let sectionsToUpdate = sectionsInOldBounds + sectionsInNewBounds
                let headerPaths = sectionsToUpdate.flatMap { sectionIndex, section -> IndexPath in
                    section.headerAttributes = nil
                    return IndexPath(item: 0, section: sectionIndex)
                } as [IndexPath]
                invalidationContext.invalidateSupplementaryElements(ofKind: UICollectionElementKindSectionHeader,
                                                                    at: headerPaths)
            }
        }
        return invalidationContext
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let oldBounds = self.collectionView?.bounds else { return false }
        if oldBounds.size != newBounds.size { return true }
        if self.sectionHeadersPinToVisibleBounds && oldBounds.origin != newBounds.origin { return true }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
}
