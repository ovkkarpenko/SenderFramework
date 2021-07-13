//
// Created by Roman Serga on 3/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension IndexPath {
    var messagesDay: Int {
        return self[0]
    }

    var message: Int {
        return self[1]
    }

    init(messagesDay: Int, message: Int) {
        self.init(arrayLiteral: messagesDay, message)
    }
}

protocol ChatMessagesViewModelProtocol {
    var messagesDays: SortedCollection<MessagesDay> { get }

    func indexPathFor(message: AbstractMessageViewModel) -> IndexPath?
    func messageFor(indexPath: IndexPath) -> AbstractMessageViewModel?
    func formMessageIndexPathWith(_ messageIndexPath: IndexPath, offsetBy offset: Int) -> IndexPath?
    func messagesCountBetween(_ indexPath1: IndexPath, _ indexPath2: IndexPath) -> Int?
}

struct ChatMessagesViewModelChange {
    let viewModel: AbstractMessageViewModel
    let oldIndexPath: IndexPath?
    let newIndexPath: IndexPath?
    let isNewMessagesDay: Bool
    let isDeletedMessagesDay: Bool

    init(viewModel: AbstractMessageViewModel,
         oldIndexPath: IndexPath? = nil,
         newIndexPath: IndexPath? = nil,
         isNewMessagesDay: Bool = false,
         isDeletedMessagesDay: Bool = false) {
        self.viewModel = viewModel
        self.oldIndexPath = oldIndexPath
        self.newIndexPath = newIndexPath
        self.isNewMessagesDay = isNewMessagesDay
        self.isDeletedMessagesDay = isDeletedMessagesDay
    }
}

struct ChatMessagesViewModel: ChatMessagesViewModelProtocol {

    fileprivate(set) var messagesDays: SortedCollection<MessagesDay>

    fileprivate let daysSortComparator: (Any, Any) -> ComparisonResult = { obj1, obj2 in
        guard let day1 = obj1 as? MessagesDay,
              let day2 = obj2 as? MessagesDay else {
            fatalError("Error. Array contains non-MessagesDay object")
        }
        return day1.date < day2.date ? .orderedAscending : (day1.date > day2.date ? .orderedDescending : .orderedSame)
    }

    fileprivate let messagesSortComparator: (Any, Any) -> ComparisonResult = { obj1, obj2 in
        guard let message1 = obj1 as? AbstractMessageViewModel,
              let message2 = obj2 as? AbstractMessageViewModel else {
            fatalError("Error. Array contains non-MessageViewModel object")
        }

        if message1.creationTime < message2.creationTime {
            return .orderedAscending
        } else if message1.creationTime > message2.creationTime {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    var storeDeletedMessages: Bool = false

    init() {
        self.messagesDays = SortedCollection<MessagesDay>(sortComparator: self.daysSortComparator)
    }

    init(messages: [Message], gaps: [MessagesGap]) {
        self.init()
        _ = self.setMessages(messages, gaps: gaps)
    }

    func messagesDayFor(creationTime: Date) -> (MessagesDay, Int)? {
        let sortedRange = NSRange(location: 0, length: self.messagesDays.count)
        let messagesDaysDates = self.messagesDays.map({return $0.date}) as NSArray
        let index = messagesDaysDates.index(of: creationTime,
                                            inSortedRange: sortedRange,
                                            options: .firstEqual) { obj1, obj2 in
            guard let date1 = obj1 as? Date,
                  let date2 = obj2 as? Date else {
                fatalError("Error. Array contains non-Date object")
            }
            let calendar = NSCalendar.current
            if calendar.isDate(date1, inSameDayAs: date2) {
                return .orderedSame
            } else {
                return date1 < date2 ? .orderedAscending : .orderedDescending
            }
        }
        guard index != NSNotFound else { return nil }
        return (self.messagesDays[index], index)
    }

    func messagesDayFor(message: AbstractMessageViewModel) -> (MessagesDay, Int, Int)? {
        guard let (messagesDay, messagesDayIndex) = self.messagesDayFor(creationTime: message.creationTime),
              let messageIndex = messagesDay.messages.index(of: message) else {
            return nil
        }
        return (messagesDay, messagesDayIndex, messageIndex)
    }

    func messageViewModelFor(message: Message) -> AbstractMessageViewModel? {
        let tempViewModel = self.createViewModelFor(message: message)
        guard let realModelIndexPath = self.indexPathFor(message: tempViewModel) else { return nil }
        return self.messageFor(indexPath: realModelIndexPath)
    }

    //MARK : - Fabric methods

    func createViewModelFor(message: Message) -> AbstractMessageViewModel {
        switch message.type {
        case "FORM": return FormMessageViewModel(message: message)
        case "TEXT": return TextMessageViewModel(message: message)
        case "IMAGE": return ImageMessageViewModel(message: message)
        case "VIDEO": return VideoMessageViewModel(message: message)
        case "AUDIO": return AudioMessageViewModel(message: message)
        case "SELFLOCATION": return LocationMessageViewModel(message: message)
        case "STICKER": return StickerMessageViewModel(message: message)
        case "VIBRO": return VibroChatMessageViewModel(message: message)
        case "FILE": return FileMessageViewModel(message: message)
        case "NOTIFICATION", "KEYCHAT": return NotificationViewModel(message: message)
        default: return MessageViewModel(message: message)
        }
    }

    func createViewModelFor(gap: MessagesGap) -> AbstractMessageViewModel {
        return GapMessageViewModel(gap: gap)
    }

    //MARK : - Working with Message

    mutating func setMessages(_ messages: [Message], gaps: [MessagesGap]) -> [ChatMessagesViewModelChange] {
        self.messagesDays.removeAll()
        var changes = self.addMessages(messages)
        changes.append(contentsOf: self.addGaps(gaps))
        return changes
    }

    mutating func updateMessages(_ messages: [Message]) -> [ChatMessagesViewModelChange] {
        let messagesViewModels = messages.flatMap {
            return $0.created != nil ? self.createViewModelFor(message: $0) : nil
        } as [AbstractMessageViewModel]
        let changes = self.updateMessageViewModels(messagesViewModels)
        return changes.0 + changes.1
    }

    mutating func addMessages(_ messages: [Message]) -> [ChatMessagesViewModelChange] {
        let messagesViewModels = messages.flatMap {
            return $0.created != nil ? self.createViewModelFor(message: $0) : nil
        } as [AbstractMessageViewModel]
        let changes = self.addMessageViewModels(messagesViewModels)
        return changes.0 + changes.1
    }

    mutating func removeMessages(_ messages: [Message]) -> [ChatMessagesViewModelChange] {
        let messagesViewModels = messages.flatMap {
            return $0.created != nil ? self.createViewModelFor(message: $0) : nil
        } as [AbstractMessageViewModel]
        let changes = self.removeMessageViewModels(messagesViewModels)
        return changes.0 + changes.1
    }

    //MARK : - Working with MessagesGap

    mutating func addGaps(_ gaps: [MessagesGap]) -> [ChatMessagesViewModelChange] {
        let messagesViewModels = gaps.flatMap {
            return $0.created != nil ? self.createViewModelFor(gap: $0) : nil
        } as [AbstractMessageViewModel]
        let changes = self.addMessageViewModels(messagesViewModels)
        return changes.0 + changes.1
    }

    mutating func removeGaps(_ gaps: [MessagesGap]) -> [ChatMessagesViewModelChange] {
        let messagesViewModels = gaps.flatMap {
            return self.createViewModelFor(gap: $0)
        } as [AbstractMessageViewModel]
        let changes = self.removeMessageViewModels(messagesViewModels)
        return changes.0 + changes.1
    }

    fileprivate mutating func addMessagesDay(_ messagesDay: MessagesDay) -> Int {
        return self.messagesDays.add(messagesDay)
    }
}

//MARK : - Working with AbstractMessageViewModel
extension ChatMessagesViewModel {

    /*
        IndexPaths of removing changes are valid for MessagesViewModel before deleting any message.
        IndexPaths of updating changes are valid for MessagesViewModel after deleting all messages.
    */
    mutating fileprivate func removeMessageViewModels(_ messages: [AbstractMessageViewModel])
                    -> ([ChatMessagesViewModelChange], [ChatMessagesViewModelChange]) {
        var dayChanges = [Int: (day: MessagesDay, messages: [AbstractMessageViewModel])]()
        var deletedDays = [MessagesDay]()
        var messagesAfterRemoved = [AbstractMessageViewModel]()

        let removeChanges = messages.flatMap { message -> ChatMessagesViewModelChange? in
            guard let (oldMessagesDay, oldMessagesDayIndex, messageIndex) = self.messagesDayFor(message: message) else {
                return nil
            }
            var messagesDayToDelete: MessagesDay?

            if let existingChange = dayChanges[oldMessagesDayIndex] {
                guard !existingChange.messages.contains(message) else { return nil }
                var newMessages = existingChange.messages
                newMessages.append(message)
                let newChange = (existingChange.day, newMessages)
                dayChanges[oldMessagesDayIndex] = newChange
                if newChange.0.messages.count == newChange.1.count {
                    messagesDayToDelete = existingChange.day
                }
            } else {
                let newChange = (oldMessagesDay, [message])
                dayChanges[oldMessagesDayIndex] = newChange
                if oldMessagesDay.messages.count == newChange.1.count {
                    messagesDayToDelete = oldMessagesDay
                }
            }

            let nextMessageIndex = messageIndex + 1
            if nextMessageIndex < oldMessagesDay.messages.count {
                messagesAfterRemoved.append(oldMessagesDay.messages[nextMessageIndex])
            }

            if let messagesDayToDelete = messagesDayToDelete { deletedDays.append(messagesDayToDelete) }
            let oldIndexPath = IndexPath(messagesDay: oldMessagesDayIndex, message: messageIndex)
            let removeChange = ChatMessagesViewModelChange(viewModel: message,
                                                           oldIndexPath: oldIndexPath,
                                                           isDeletedMessagesDay: messagesDayToDelete != nil)

            return removeChange
        }

        for (index, change) in dayChanges {
            var dayWithDeletedMessages = change.0
            change.1.forEach { _ = dayWithDeletedMessages.remove($0) }
            self.messagesDays[index] = dayWithDeletedMessages
        }
        deletedDays.forEach { _ = self.messagesDays.remove($0) }

        let gluedMessagesUpdates = messagesAfterRemoved.flatMap { message -> ChatMessagesViewModelChange? in
            guard let indexPath = self.indexPathFor(message: message) else { return nil }
            let messagesDay = self.messagesDays[indexPath.messagesDay]
            return self.updateIsGluedOfMessageAt(index: indexPath.message,
                                                 previousMessageIndex: indexPath.message - 1,
                                                 inMessagesDay: messagesDay,
                                                 messagesDayIndex: indexPath.messagesDay)
        }

        return (removeChanges, gluedMessagesUpdates)
    }

    /*
        IndexPaths of adding changes are valid for MessagesViewModel after adding all messages.
        IndexPaths of updating changes are valid for MessagesViewModel after adding all messages.
    */
    mutating fileprivate func addMessageViewModels(_ messages: [AbstractMessageViewModel])
                    -> ([ChatMessagesViewModelChange], [ChatMessagesViewModelChange]) {
        let sortedMessages = messages.sorted { self.messagesSortComparator($0, $1) != .orderedDescending }
        var gluedMessagesUpdates = [ChatMessagesViewModelChange]()
        let addChanges = sortedMessages.flatMap { message -> ChatMessagesViewModelChange? in
            guard self.storeDeletedMessages || !message.isDeleted else { return nil }
            let addUpdate = self.addMessageViewModel(message)
            return addUpdate
        }

        gluedMessagesUpdates = addChanges.flatMap { change -> ChatMessagesViewModelChange? in
            guard let newIndexPath = change.newIndexPath else { return nil }
            let messagesDay = self.messagesDays[newIndexPath.messagesDay]
            let nextMessageIndex = newIndexPath.message + 1
            guard nextMessageIndex < messagesDay.messages.count else { return nil }
            let nextMessage = messagesDay.messages[nextMessageIndex]
            return self.updateIsGluedOfMessage(nextMessage,
                                               previousMessage: change.viewModel,
                                               withUpdateIndex: nextMessageIndex,
                                               inMessagesDay: messagesDay,
                                               messagesDayIndex: newIndexPath.messagesDay)
        }

        return (addChanges, gluedMessagesUpdates)
    }

    /*
        Does nothing and returns nil, if message is already contained in ChatMessageViewModel
    */
    mutating fileprivate func addMessageViewModel(_ message: AbstractMessageViewModel) -> ChatMessagesViewModelChange? {
        let newMessagesDayIndex: Int
        let newMessageIndex: Int
        let isNewMessagesDay: Bool

        guard self.indexPathFor(message: message) == nil else { return nil }

        if let (existingMessagesDay, index) = self.messagesDayFor(creationTime: message.creationTime) {
            newMessagesDayIndex = index
            var messagesDayWithAddedMessage = existingMessagesDay
            newMessageIndex = messagesDayWithAddedMessage.add(message)
            self.messagesDays[newMessagesDayIndex] = messagesDayWithAddedMessage
            isNewMessagesDay = false
        } else {
            let newMessagesDay = MessagesDay(message: message, messagesSortComparator: self.messagesSortComparator)
            newMessageIndex = 0
            newMessagesDayIndex = self.addMessagesDay(newMessagesDay)
            isNewMessagesDay = true
        }
        let changeIndexPath = IndexPath(messagesDay: newMessagesDayIndex, message: newMessageIndex)

        if let messageModel = message as? MessageViewModel {
            let previousMessageIndexPath = IndexPath(messagesDay: changeIndexPath.messagesDay,
                                                     message: changeIndexPath.message - 1)
            let isMessageGlued: Bool
            if let previousMessage = self.messageFor(indexPath: previousMessageIndexPath) {
                isMessageGlued = self.isMessageGluedWithPrevious(message: message, previousMessage: previousMessage)
            } else {
                isMessageGlued = false
            }
            messageModel.isGluedWithPreviousMessage = isMessageGlued
        }

        let addChange = ChatMessagesViewModelChange(viewModel: message,
                                                    newIndexPath: changeIndexPath,
                                                    isNewMessagesDay: isNewMessagesDay)
        return addChange
    }

    /*
        IndexPaths of removing changes are valid for MessagesViewModel before deleting any message.
        IndexPaths of adding changes are valid for MessagesViewModel after adding all messages.
        IndexPaths of updating changes are valid for MessagesViewModel after adding and removing all messages.
        oldIndexPath of moving changes are valid for MessagesViewModel before deleting any message,
        newIndexPath of moving changes are valid for MessagesViewModel after adding all messages.
    */
    mutating fileprivate func updateMessageViewModels(_ messages: [AbstractMessageViewModel])
                    -> ([ChatMessagesViewModelChange], [ChatMessagesViewModelChange]) {
        let sortedMessages = messages.sorted { self.messagesSortComparator($0, $1) != .orderedDescending }
        let removeChanges = self.removeMessageViewModels(sortedMessages)

        let messagesAfterRemovedMessages = removeChanges.0.flatMap { change -> AbstractMessageViewModel? in
            guard let oldIndexPath = change.oldIndexPath else { return nil }
            return self.messageFor(indexPath: oldIndexPath)
        }

        var gluedMessagesUpdates = [ChatMessagesViewModelChange]()

        let updateChanges = removeChanges.0.flatMap { removeChange -> ChatMessagesViewModelChange in
            let oldIsGlued = removeChange.viewModel.isGluedWithPreviousMessage

            guard self.storeDeletedMessages || !removeChange.viewModel.isDeleted,
                  let addChange = self.addMessageViewModel(removeChange.viewModel) else { return removeChange }

            let isNewMessagesDay: Bool
            let isDeletedMessagesDay: Bool
            if removeChange.oldIndexPath == addChange.newIndexPath {
                isNewMessagesDay = false
                isDeletedMessagesDay = false
            } else {
                isNewMessagesDay = addChange.isNewMessagesDay
                isDeletedMessagesDay = removeChange.isDeletedMessagesDay
            }
            let updateChange = ChatMessagesViewModelChange(viewModel: addChange.viewModel,
                                                           oldIndexPath: removeChange.oldIndexPath,
                                                           newIndexPath: addChange.newIndexPath,
                                                           isNewMessagesDay: isNewMessagesDay,
                                                           isDeletedMessagesDay: isDeletedMessagesDay)
            if addChange.viewModel.isGluedWithPreviousMessage != oldIsGlued {
                gluedMessagesUpdates.append(ChatMessagesViewModelChange(viewModel: addChange.viewModel,
                                                                        oldIndexPath: addChange.newIndexPath,
                                                                        newIndexPath: addChange.newIndexPath))
            }
            return updateChange
        }

        gluedMessagesUpdates.append(contentsOf: updateChanges.flatMap { change -> ChatMessagesViewModelChange? in
            guard let newIndexPath = change.newIndexPath else { return nil }
            let messagesDay = self.messagesDays[newIndexPath.messagesDay]
            let nextMessageIndex = newIndexPath.message + 1
            guard nextMessageIndex < messagesDay.messages.count else { return nil }
            let nextMessage = messagesDay.messages[nextMessageIndex]
            return self.updateIsGluedOfMessage(nextMessage,
                                               previousMessage: change.viewModel,
                                               withUpdateIndex: nextMessageIndex,
                                               inMessagesDay: messagesDay,
                                               messagesDayIndex: newIndexPath.messagesDay)
        })

        messagesAfterRemovedMessages.forEach { message in
            guard let indexPath = self.indexPathFor(message: message) else { return }
            let messagesDay = self.messagesDays[indexPath.messagesDay]
            if let gluedMessageUpdate = self.updateIsGluedOfMessageAt(index: indexPath.message,
                                                                      previousMessageIndex: indexPath.message - 1,
                                                                      inMessagesDay: messagesDay,
                                                                      messagesDayIndex: indexPath.messagesDay) {
                gluedMessagesUpdates.append(gluedMessageUpdate)
            }
        }

        return (updateChanges, gluedMessagesUpdates)
    }

    fileprivate func updateIsGluedOfMessageAt(index: Int,
                                              previousMessageIndex: Int,
                                              inMessagesDay messagesDay: MessagesDay,
                                              messagesDayIndex: Int) -> ChatMessagesViewModelChange? {
        if index >= 0, index < messagesDay.messages.count,
           let previousMessage = self.messageFor(indexPath: IndexPath(messagesDay: messagesDayIndex,
                                                                      message: previousMessageIndex)) {
            let message = messagesDay.messages[index]
            let newIsGlued = self.isMessageGluedWithPrevious(message: message, previousMessage: previousMessage)
            if newIsGlued != message.isGluedWithPreviousMessage {
                message.isGluedWithPreviousMessage = newIsGlued
                let updatePath = IndexPath(messagesDay: messagesDayIndex, message: index)
                return ChatMessagesViewModelChange(viewModel: message,
                                                   oldIndexPath: updatePath,
                                                   newIndexPath: updatePath)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    fileprivate func updateIsGluedOfMessage(_ message: AbstractMessageViewModel,
                                            previousMessage: AbstractMessageViewModel,
                                            withUpdateIndex updateIndex: Int,
                                            inMessagesDay messagesDay: MessagesDay,
                                            messagesDayIndex: Int) -> ChatMessagesViewModelChange? {
        guard let concreteMessageModel = message as? MessageViewModel else { return nil }
        let newIsGlued = self.isMessageGluedWithPrevious(message: message, previousMessage: previousMessage)
        if newIsGlued != concreteMessageModel.isGluedWithPreviousMessage {
            concreteMessageModel.isGluedWithPreviousMessage = newIsGlued
            let updatePath = IndexPath(messagesDay: messagesDayIndex, message: updateIndex)
            return ChatMessagesViewModelChange(viewModel: message,
                                               oldIndexPath: updatePath,
                                               newIndexPath: updatePath)
        } else {
            return nil
        }
    }

    fileprivate func isMessageGluedWithPrevious(message: AbstractMessageViewModel,
                                                previousMessage: AbstractMessageViewModel) -> Bool {
        guard let concreteMessageModel = message as? MessageViewModel,
              concreteMessageModel.author == .interlocutor,
              let previousMessage = previousMessage as? MessageViewModel,
              concreteMessageModel.fromID == previousMessage.fromID else {
            return false
        }
        return concreteMessageModel.creationTime.timeIntervalSince(previousMessage.creationTime) < 3 * 60
    }
}

//MARK : - IndexPath Manipulation
extension ChatMessagesViewModel {
    func indexPathFor(message: AbstractMessageViewModel) -> IndexPath? {
        guard let (_, messageDayIndex, messageIndex) = self.messagesDayFor(message: message) else {
            return nil
        }
        return IndexPath(messagesDay: messageDayIndex, message: messageIndex)
    }

    func messageFor(indexPath: IndexPath) -> AbstractMessageViewModel? {
        guard self.validateIndexPath(indexPath)  else { return nil }
        let messagesDay = self.messagesDays[indexPath.messagesDay]
        return messagesDay.messages[indexPath.message]
    }

    func formMessageIndexPathWith(_ messageIndexPath: IndexPath, offsetBy offset: Int) -> IndexPath? {
        guard self.messagesDays.count > messageIndexPath.messagesDay else { return nil }

        let messagesDay = self.messagesDays[messageIndexPath.messagesDay]
        let newMessageIndex = messageIndexPath.message + offset
        if newMessageIndex < 0 {
            let nextDayIndex = messageIndexPath.messagesDay - 1
            guard nextDayIndex >= 0 else { return nil }
            let nextDayMessagesCount = self.messagesDays[nextDayIndex].messages.count
            guard nextDayMessagesCount > 0 else { return nil }
            let nextDayIndexPath = IndexPath(messagesDay: nextDayIndex, message: nextDayMessagesCount - 1)
            let delta = newMessageIndex + 1
            if delta == 0 {
                return nextDayIndexPath
            } else {
                return formMessageIndexPathWith(nextDayIndexPath, offsetBy: delta)
            }
        } else if newMessageIndex >= messagesDay.messages.count {
            let nextDayIndex = messageIndexPath.messagesDay + 1
            guard nextDayIndex < self.messagesDays.count,
                  !self.messagesDays[nextDayIndex].messages.isEmpty else { return nil }
            let nextDayIndexPath = IndexPath(messagesDay: nextDayIndex, message: 0)
            let delta = newMessageIndex - messagesDay.messages.count
            if delta == 0 {
                return nextDayIndexPath
            } else {
                return formMessageIndexPathWith(nextDayIndexPath, offsetBy: delta)
            }
        } else {
            return IndexPath(messagesDay: messageIndexPath.messagesDay, message: newMessageIndex)
        }
    }

    func validateIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.messagesDay >= 0, indexPath.messagesDay < self.messagesDays.count else { return false }
        let messagesDay = self.messagesDays[indexPath.messagesDay]
        return indexPath.message >= 0 && indexPath.message < messagesDay.messages.count
    }

    func messagesCountBetween(_ indexPath1: IndexPath, _ indexPath2: IndexPath) -> Int? {
        guard self.validateIndexPath(indexPath1) && self.validateIndexPath(indexPath2) else { return nil }
        var messagesCount = 0

        let smallerIndexPath: IndexPath
        let biggerIndexPath: IndexPath

        let isIndexPath1Smaller = indexPath1.messagesDay < indexPath2.messagesDay ||
                indexPath1.messagesDay == indexPath2.messagesDay && indexPath1.message < indexPath2.message

        smallerIndexPath = isIndexPath1Smaller ? indexPath1 : indexPath2
        biggerIndexPath = isIndexPath1Smaller ? indexPath2 : indexPath1

        guard smallerIndexPath.messagesDay != biggerIndexPath.messagesDay else {
            return biggerIndexPath.message - smallerIndexPath.message
        }

        for messagesDayIndex in (smallerIndexPath.messagesDay)...(biggerIndexPath.messagesDay) {
            let messagesDay = self.messagesDays[messagesDayIndex]
            if messagesDayIndex == smallerIndexPath.messagesDay {
                messagesCount += messagesDay.messages.count - smallerIndexPath.message
            } else if messagesDayIndex == biggerIndexPath.messagesDay {
                messagesCount += biggerIndexPath.message
            } else {
                messagesCount += messagesDay.messages.count
            }
        }
        return messagesCount
    }
}
