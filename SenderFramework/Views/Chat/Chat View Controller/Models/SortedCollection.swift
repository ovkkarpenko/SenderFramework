//
// Created by Roman Serga on 21/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

struct SortedCollection<Element>:RandomAccessCollection, MutableCollection where Element: Equatable {
    typealias Index = Array<Element>.Index
    typealias Indices = Array<Element>.Indices
    typealias SubSequence = Array<Element>.SubSequence
    typealias Iterator = Array<Element>.Iterator
    typealias IndexDistance = Array<Element>.IndexDistance

    fileprivate var elements = [Element]()

    var sortComparator: (Element, Element) -> ComparisonResult
    var count: Int { return  self.elements.count }
    var startIndex: Index { return self.elements.startIndex }
    var endIndex: Index { return self.elements.endIndex }
    var indices: Indices { return self.elements.indices}
    var underestimatedCount: Int { return self.elements.underestimatedCount }

    subscript(position: Index) -> Element {
        get {
            return self.elements[position]
        }
        set(newValue) {
            self.elements[position] = newValue
        }
    }

    fileprivate var objcSortComparator: (Any, Any) -> ComparisonResult {
        return { obj1, obj2 in
            guard let element1 = obj1 as? Element, let element2 = obj2 as? Element else {
                fatalError("Wrong type inside elements array")
            }
            return self.sortComparator(element1, element2)
        }
    }

    init(sortComparator: @escaping (Any, Any) -> ComparisonResult, elements: [Element] = [Element]()) {
        self.sortComparator = sortComparator
        self.elements = elements.sorted { return self.sortComparator($0, $1) != .orderedDescending }
    }

    mutating func add(_ element: Element) -> Int {
        let sortedRange = NSRange(location: 0, length: self.elements.count)
        let insertionIndex = (self.elements as NSArray).index(of: element,
                                                              inSortedRange: sortedRange,
                                                              options: .insertionIndex,
                                                              usingComparator: self.objcSortComparator)
        self.elements.insert(element, at: insertionIndex)
        return insertionIndex
    }

    mutating func removeAll() {
        self.elements.removeAll()
    }

    /*
        If there are multiple instances, equal to 'element' in array, deletes first equal element
    */
    mutating func remove(_ element: Element) -> Int? {
        guard let deletionIndex = self.index(of: element) else { return nil }
        self.elements.remove(at: deletionIndex)
        return deletionIndex
    }

    /*
        If there are multiple instances, equal to 'element' in array, returns index of first equal element
    */
    func index(of element: Element) -> Int? {
        return self.elements.index(of: element)
    }

    /*
        Returns nil if element is already in SortedCollection
    */
    func insertionIndexFor(_ element: Element) -> Int? {
        guard self.index(of: element) == nil else { return nil }
        let sortedRange = NSRange(location: 0, length: self.elements.count)
        return (self.elements as NSArray).index(of: element,
                                                inSortedRange: sortedRange,
                                                options: .insertionIndex,
                                                usingComparator: self.objcSortComparator)
    }

    mutating func update(_ element: Element) -> (oldIndex: Int?, newIndex: Int?) {
        guard let oldIndex = self.remove(element) else { return (nil, nil) }
        let newIndex = self.add(element)
        return (oldIndex, newIndex)
    }

    func formIndex(before i: inout Index) {
        self.elements.formIndex(before: &i)
    }

    subscript(bounds: Range<Index>) -> SubSequence {
        return self.elements[bounds]
    }

    func index(_ i: Index, offsetBy n: Int) -> Index {
        return self.elements.index(i, offsetBy: n)
    }

    func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {
        return self.elements.index(i, offsetBy: n, limitedBy: limit)
    }

    func distance(from start: Index, to end: Index) -> Int {
        return self.elements.distance(from: start, to: end)
    }

    func makeIterator() -> Iterator {
        return self.elements.makeIterator()
    }

    func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        return try self.elements.map(transform)
    }

    func dropLast(_ n: Int) -> SubSequence {
        return self.elements.dropLast(n)
    }

    func suffix(_ maxLength: Int) -> SubSequence {
        return self.elements.suffix(maxLength)
    }
}
