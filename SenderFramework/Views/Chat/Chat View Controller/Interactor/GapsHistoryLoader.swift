//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GapsHistoryLoader {
    var dataManager: ChatDataManagerProtocol

    let historyLoadingQueue = DispatchQueue(label: "com.SenderFramework.gapsHistoryLoadingQueue")
    let gapsAccessQueue = DispatchQueue(label: "com.SenderFramework.gapsAccessQueue")
    var gapsInProgress = [MessagesGap]()

    init(dataManager: ChatDataManagerProtocol) {
        self.dataManager = dataManager
    }

    func loadHistoryFor(gap: MessagesGap, chatID: String, completion: ((MessagesParsingResult?, Error?) -> Void)?) {
        var shouldHandleGap = false
        gapsAccessQueue.sync {
            shouldHandleGap = self.gapsInProgress.index(of: gap) == nil
            if shouldHandleGap { self.gapsInProgress.append(gap) }
        }
        guard shouldHandleGap else { NSLog("Not loading gap: \(gap)"); return }

        historyLoadingQueue.async {
            let semaphore = DispatchSemaphore(value: 0)
            NSLog("Starting loading for \(gap)")
            self.dataManager.loadHistoryWith(chatID: chatID,
                                             startPacketID: gap.startPacketID.intValue,
                                             endPacketID: gap.endPacketID.intValue) { result, error in
                self.gapsAccessQueue.sync {
                    if let gapIndex = self.gapsInProgress.index(of: gap) { self.gapsInProgress.remove(at: gapIndex) }
                }
                semaphore.signal()
                NSLog("Finished loading for \(gap)")
                completion?(result, error)
            }
            _ = semaphore.wait(timeout: .now() + 10.0)
        }
    }
}
