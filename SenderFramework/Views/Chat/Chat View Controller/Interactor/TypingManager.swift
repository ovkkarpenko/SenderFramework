//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol TypingManagerDelegate: class {
    func typingManager(_ typingManager: TypingManager, didChangeTypingUsers newTypingUsers: [Contact])
}

class TypingManager {
    var typingDuration: TimeInterval
    var typingUsers = [String: (Contact, Timer)]()
    weak var delegate: TypingManagerDelegate?

    init(typingDuration: TimeInterval = 2) {
        self.typingDuration = typingDuration
    }

    func usersStartedTyping(_ users: [Contact]) {
        for contact in users {
            guard contact.userID != nil else { continue }
            if let (_, currentStopTypingTimer) = self.typingUsers[contact.userID] {
                currentStopTypingTimer.invalidate()
            }

            let stopTypingTimer = Timer.scheduledTimer(timeInterval: self.typingDuration, target: BlockOperation {
                guard let (_, stopTypingTimer) = self.typingUsers[contact.userID] else { return }
                stopTypingTimer.invalidate()
                self.typingUsers[contact.userID] = nil
                self.sendTypingUsersChange()
            }, selector: #selector(BlockOperation.main), userInfo: nil, repeats: false)

            self.typingUsers[contact.userID] = (contact, stopTypingTimer)
            self.sendTypingUsersChange()
        }
    }

    func sendTypingUsersChange() {
        let typingContacts = Array(self.typingUsers.values.map({ $0.0 }))
        self.delegate?.typingManager(self, didChangeTypingUsers: typingContacts)
    }
}
