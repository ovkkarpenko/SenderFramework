//
// Created by Roman Serga on 28/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class AudioMessagesLoader {

    let messageFileManager: MessageFileManager

    let messagesCompletions = MW_PSPDFThreadSafeMutableDictionary()

    init(messageFileManager: MessageFileManager) {
        self.messageFileManager = messageFileManager
    }

    func isMessageValidForLoading(_ message: Message) -> Bool {
        return message.file.localUrl == nil && message.file.url != nil
    }

    func loadAudioFor(message: Message, completion: @escaping ((URL?, Error?) -> Void)) {
        guard let messageID = message.moId else {
            let error = NSError(domain: "Message has no moId", code: 666)
            completion(nil, error)
            return
        }

        if var existingCompletions = self.messagesCompletions[messageID] as? [((URL?, Error?) -> Void)] {
            existingCompletions.append(completion)
            messagesCompletions[messageID] = existingCompletions
        } else {
            let completions = [completion]
            messagesCompletions[messageID] = completions
            self.messageFileManager.loadAudioFor(message: message) { url, error in
                guard let messageCompletions = self.messagesCompletions[messageID] as? [((URL?, Error?) -> Void)] else {
                    return
                }
                messageCompletions.forEach { completion in completion(url, error) }
                self.messagesCompletions[messageID] = nil
            }
        }
    }
}
