//
// Created by Roman Serga on 21/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

struct MessagesDay: Equatable {
    var date: Date
    var description: String
    var messages: SortedCollection<AbstractMessageViewModel>

    let messagesSortComparator: (Any, Any) -> ComparisonResult

    init(date: Date, messagesSortComparator: @escaping (Any, Any) -> ComparisonResult) {
        self.date = date
        self.messagesSortComparator = messagesSortComparator
        self.description = date.description
        self.messages = SortedCollection<AbstractMessageViewModel>(sortComparator: messagesSortComparator)
    }

    /*
        Creates messages day with start of message's creationTime day.
        message is guarantied to be first in messagesArray
    */
    init(message: AbstractMessageViewModel, messagesSortComparator: @escaping (Any, Any) -> ComparisonResult) {
        let calendar = NSCalendar.current
        let startOfDay = calendar.startOfDay(for: message.creationTime)
        self.init(date: startOfDay, messagesSortComparator: messagesSortComparator)
        _ = self.messages.add(message)
    }

    mutating func add(_ message: AbstractMessageViewModel) -> Int {
        return self.messages.add(message)
    }

    mutating func remove(_ message: AbstractMessageViewModel) -> Int? {
        return self.messages.remove(message)
    }

    mutating func update(_ message: AbstractMessageViewModel) -> (oldIndex: Int?, newIndex: Int?) {
        return self.messages.update(message)
    }

    public static func == (lhs: MessagesDay, rhs: MessagesDay) -> Bool {
        return lhs.date == rhs.date
    }
}
