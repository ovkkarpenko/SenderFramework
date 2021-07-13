//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol EmptyAble {
    var isEmpty: Bool {get set}
    init(emptyElement empty: Bool)
}

struct ArrayWithSeparator<ElementType: EmptyAble> : Collection {

    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return i + 1
    }

    var firstPart = [ElementType]()
    var secondPart = [ElementType]()
    fileprivate let separator = ElementType(emptyElement: true)

    typealias Index = Int
    typealias IndexDistance = Int

    var startIndex: Index {
        return 0
    }

    var endIndex: Index {
        return firstPart.count + secondPart.count
    }

    var count: IndexDistance {
        return self.endIndex + 1
    }

    subscript(i: Index) -> ElementType {
        switch i {
        case 0..<firstPart.count:
            return firstPart[i]
        case (firstPart.count + 1)..<(self.count):
            return secondPart[i - (firstPart.count + 1)]
        default:
            return separator
        }
    }
}
