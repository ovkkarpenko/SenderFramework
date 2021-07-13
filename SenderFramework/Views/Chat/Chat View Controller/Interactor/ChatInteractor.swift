//
// Created by Roman Serga on 10/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

extension Dialog {
    var lastReadMessage: Message? {
        guard self.unreadCount == 0, let foreignMessages = self.foreignMessages else { return nil }
        return foreignMessages.last
    }

    var foreignMessages: [Message]? {
        guard let messages = self.messages?.array as? [Message] else { return nil }
        return messages.filter { !$0.owner }
    }
}

fileprivate struct ChatKeysCache: Equatable {
    let oldOldGroupKeysData: Data?
    let oldGroupEncryptionKey: Data?
    let oldP2PEncryptionKey: Data?

    init(chat: Dialog) {
        self.oldOldGroupKeysData = chat.oldGroupKeysData
        self.oldGroupEncryptionKey = chat.encryptionKey
        self.oldP2PEncryptionKey = chat.p2pBTCKeyData
    }

    fileprivate static func ==(lhs: ChatKeysCache, rhs: ChatKeysCache) -> Bool {
        return lhs.oldOldGroupKeysData == rhs.oldOldGroupKeysData &&
                lhs.oldGroupEncryptionKey == rhs.oldGroupEncryptionKey &&
                lhs.oldP2PEncryptionKey == rhs.oldP2PEncryptionKey
    }

    func areKeysDifferentFrom(chat: Dialog) -> Bool {
        return oldOldGroupKeysData != chat.oldGroupKeysData ||
                oldGroupEncryptionKey != chat.encryptionKey ||
                oldP2PEncryptionKey != chat.p2pBTCKeyData
    }
}

class ChatInteractor: ChatInteractorProtocol,
                      Chat,
                      MessagesChangesHandler,
                      ChatsChangesHandler,
                      MessagesGapsChangesHandler,
                      TypingChangesHandler,
                      TypingManagerDelegate {

    var chat: Dialog!
    var chatID: String!
    var isActive: Bool = false

    /*
        sendBarDisabled is external setting.
        Must be used in order to set whether send bar will be possible to use in chat.

        _sendBarDisabled is internal. May change if chat becomes inactive.
    */
    var sendBarDisabled: Bool = false {
        didSet {
            self._sendBarDisabled = sendBarDisabled
        }
    }

    private var _sendBarDisabled: Bool = false {
        didSet {
            self.presenter?.handleSendBarDisabledValue(sendBarDisabled: self._sendBarDisabled)
        }
    }

    var sendBarActions: [[String: Any]]?

    let historyLoadCount = UInt.max

    var lastReadMessage: Message?

    let typingDuration: TimeInterval = 2
    var typingUsers = [String: (Contact, Timer)]()

    weak var presenter: ChatPresenterProtocol?

    var dataManager: ChatDataManagerProtocol
    let historyLoader: GapsHistoryLoader
    let readSender: MessagesReadSender
    let typingManager: TypingManager

    let messagesSender: MessageSenderProtocol
    var googleUserManager: GoogleUserManagerProtocol?

    let messageFileManager: MessageFileManager
    let audioMessagesLoader: AudioMessagesLoader

    var audioPlayer: AudioMessagePlayer?

    fileprivate var chatKeysCache: ChatKeysCache?

    var fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol

    init(dataManager: ChatDataManagerProtocol,
         messagesSender: MessageSenderProtocol,
         fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol,
         googleUserManager: GoogleUserManagerProtocol?) {
        self.dataManager = dataManager
        self.historyLoader = GapsHistoryLoader(dataManager: self.dataManager)
        self.readSender = MessagesReadSender(dataManager: self.dataManager)
        self.messagesSender = messagesSender
        self.fmlActionsHandlerInteractor = fmlActionsHandlerInteractor
        self.googleUserManager = googleUserManager
        self.typingManager = TypingManager()
        let fileStore = MessageFileStore()
        self.messageFileManager = MessageFileManager(fileStore: fileStore)
        self.audioMessagesLoader = AudioMessagesLoader(messageFileManager: self.messageFileManager)
        self.typingManager.delegate = self
    }

    func loadData() {
        self.notifyPresenterAboutNewChat()
        if let sendBarActions = self.sendBarActions {
            self.presenter?.handleExternalSendBarActions(sendBarActions)
            self.sendBarActions = nil
        }
        self._sendBarDisabled = self.sendBarDisabled || !chat.isActive
        self.dataManager.startMessagesChangesObservingWith(messagesChangesHandler: self)
        self.dataManager.startChatChangesObservingWith(chatChangesHandler: self)
        self.dataManager.startMessagesGapsChangesObservingWith(messagesGapsChangesHandler: self)
        self.dataManager.startTypingObservingWith(typingChangesHandler: self)
    }

    func setActiveState(_ activeState: Bool) {
        self.isActive = activeState

        //Restarting comet in order to start receiving typing notifications
        if self.isActive && !SenderCore.shared().isPaused { CometController.sharedInstance().isPaused = false }
    }

    fileprivate func updateChatWithRemoteInfo() {
        self.loadRemoteChatInitialInfo { chat, error in
            guard let chat = chat, error == nil, chat.chatID == self.chatID else { return }
            self.updateWith(chat: chat)
        }
    }

    fileprivate func loadRemoteChatInitialInfo(completion: ((Dialog?, Error?) -> Void)?) {
        let dispatchGroup = DispatchGroup()
        var resultChat: Dialog?
        var resultError: Error?

        self.checkOnlineStatus()

        dispatchGroup.enter()
        var hasLeftInfoGroup = false
        self.dataManager.update(chat: self.chat) { chat, error in
            resultChat = chat
            resultError = error
            if !hasLeftInfoGroup {
                hasLeftInfoGroup = true
                dispatchGroup.leave()
            }
        }

        if self.chat.needSync?.boolValue ?? true {
            dispatchGroup.enter()
            var hasLeftHistoryGroup = false
            self.dataManager.loadHistoryWith(chatID: self.chatID,
                                             topPacketID: 0,
                                             messagesCount: self.historyLoadCount) { result, _ in
                if result != nil { self.chat.needSync = false }
                let messages = (self.chat.messages?.array as? [Message]) ?? []
                messages.forEach { $0.isLoadingFile = false }
                let gaps = Array(self.chat.gaps ?? Set())
                self.audioPlayer?.stop()
                self.presenter?.messagesWereSet(messages, gaps: gaps)
                if !hasLeftHistoryGroup {
                    hasLeftHistoryGroup = true
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) { completion?(resultChat, resultError) }
    }

    func loadTopHistory() {
        /*
            If chat contains unsent messages, they will be first by order in messages.
            But it will be wrong to request history for them.
            Unsent messages has alphanumeric packetIDs, so we'll take first message with numeric packet id.
        */
        let topPacketID: Int
        if let messages = self.chat.messages {
            topPacketID = (Array(messages).lazy.flatMap({
                let packetID = ($0 as? Message)?.packetID
                return packetID != nil ? Int(packetID!) : nil
            }).first) ?? 0
        } else {
            topPacketID = 0
        }
        self.dataManager.loadHistoryWith(chatID: self.chatID,
                                         topPacketID: topPacketID,
                                         messagesCount: self.historyLoadCount) { parsingResult, _ in
            if let parsingResult = parsingResult {
                SenderCore.shared().interfaceUpdater.messagesWereUpdated(parsingResult.updatedMessages)
                SenderCore.shared().interfaceUpdater.messagesWereAdded(parsingResult.addedMessages)
                SenderCore.shared().interfaceUpdater.messagesGapsWereAdded(parsingResult.addedGaps)
            }
            self.presenter?.finishLoadingTopHistory()
        }
    }

    fileprivate func checkOnlineStatus() {
        if self.chat.chatType == .P2P, let p2pContact = self.chat.p2pContact {
            if Date().timeIntervalSince(p2pContact.lastOnlineCallTime ?? Date.distantPast) >= 60 {
                self.dataManager.requestOnlineStatusFor(contact: p2pContact)
                p2pContact.lastOnlineCallTime = Date()
            }
        }
    }

    fileprivate func notifyPresenterAboutNewChat() {
        self.presenter?.chatWasChanged(self.chat)
        self.presenter?.setUnsentText(self.chat.unsentText)
        let messages = (self.chat.messages?.array as? [Message]) ?? []
        messages.forEach { $0.isLoadingFile = false }
        let gaps = Array(self.chat.gaps ?? Set())
        self.presenter?.messagesWereSet(messages, gaps: gaps)
    }

    func updateWith(chatID: String) {
        let chat = self.dataManager.chatWith(chatID: chatID)
        self.updateWith(chat: chat)
    }

    func updateWith(chat: Dialog) {
        let isNewChat = self.chatID == nil || chat.chatID != self.chatID!
        self.chat = chat
        self.chatID = chat.chatID
        self.fmlActionsHandlerInteractor.chat = self.chat
        if isNewChat {
            self.audioPlayer?.stop()
            self.readSender.reset()
            self.lastReadMessage = self.chat.lastReadMessage
            self.notifyPresenterAboutNewChat()
            self.updateChatWithRemoteInfo()
        } else {
            self.presenter?.chatWasUpdated(self.chat)
            if let keysCache = self.chatKeysCache, keysCache.areKeysDifferentFrom(chat: self.chat) {
                self.updateEncryptedMessages()
            }
        }
        self._sendBarDisabled = self.sendBarDisabled || !chat.isActive
        self.chatKeysCache = ChatKeysCache(chat: self.chat)
    }

    func updateEncryptedMessages() {
        guard let chatMessages = Array(self.chat.messages ?? NSOrderedSet()) as? [Message] else { return }
        let messagesToUpdate = chatMessages.filter({ $0.encrypted.boolValue })
        self.handleMessagesUpdate(messagesToUpdate)
    }

    func handleChatsChange(_ chats: [Dialog]) {
        chats.forEach { chat in
            if chat.chatID == self.chatID { self.updateWith(chat: chat) }
        }
    }

    private func filterMessages(_ messages: [Message]) -> [Message] {
        return messages.filter { message in
            guard !(message is CompanyCard),
                  let messageChatID = (message.dialog?.chatID ?? message.chat) else { return false }
            return messageChatID == self.chatID
        }
    }

    func handleMessagesUpdate(_ updatedMessages: [Message]) {
        let filteredMessages = self.filterMessages(updatedMessages)
        if let activeAudioPlayer = self.audioPlayer {
            if filteredMessages.contains(where: { $0 == activeAudioPlayer.playingMessage }) {
                activeAudioPlayer.stop()
            }
        }
        if !filteredMessages.isEmpty { self.presenter?.messagesWereUpdated(filteredMessages) }
    }

    func handleMessagesAdding(_ newMessages: [Message]) {
        let filteredMessages = self.filterMessages(newMessages)
        if !filteredMessages.isEmpty { self.presenter?.messagesWereAdded(filteredMessages) }
    }

    func handleMessagesRemoval(_ removedMessages: [Message]) {
        let filteredMessages = self.filterMessages(removedMessages)
        if let activeAudioPlayer = self.audioPlayer {
            if filteredMessages.contains(where: { $0 == activeAudioPlayer.playingMessage }) {
                activeAudioPlayer.stop()
            }
        }
        if !filteredMessages.isEmpty { self.presenter?.messagesWereDeleted(filteredMessages) }
    }

    private func filterGaps(_ messagesGaps: [MessagesGap]) -> [MessagesGap] {
        return messagesGaps.filter { gap in return gap.dialog.chatID == self.chatID }
    }

    func handleGapsAdding(_ newMessagesGaps: [MessagesGap]) {
        let filteredGaps = self.filterGaps(newMessagesGaps)
        if !filteredGaps.isEmpty { self.presenter?.gapsWereAdded(filteredGaps) }
    }

    func handleGapsRemoval(_ removedMessagesGaps: [MessagesGap]) {
        let filteredGaps = self.filterGaps(removedMessagesGaps)
        if !filteredGaps.isEmpty { self.presenter?.gapsWereDeleted(filteredGaps) }
    }

    func handleTypingStartForContacts(_ contacts: [Contact], inChat chatID: String) {
        guard chatID == self.chatID else { return }
        self.typingManager.usersStartedTyping(contacts)
    }

    func typingManager(_ typingManager: TypingManager, didChangeTypingUsers newTypingUsers: [Contact]) {
        self.presenter?.typingUsersWereChanged(newTypingUsers: newTypingUsers)
    }

    func callRobot(_ callRobotModel: CallRobotModel) {
        if let robotChatID = callRobotModel.chatID {
            if robotChatID != self.chatID { self.updateWith(chatID: robotChatID) }
        } else {
            callRobotModel.chatID = self.chatID
        }
        self.dataManager.callRobotWith(model: callRobotModel, completion: nil)
    }

    func scanQRAndSendToServer() {
        self.presenter?.showQRScanner { scanResult in
            guard let qrString = scanResult else { return }
            self.dataManager.sendQRString(qrString, chatID: self.chatID, completion: nil)
        }
    }

    func messageWasShown(_ message: Message) {
        if message.type == "AUDIO", self.audioMessagesLoader.isMessageValidForLoading(message) {
            self.loadAudioFor(message: message, completion: nil)
        }

        if !message.owner {
            if let lastReadMessage = self.lastReadMessage {
                if message.packetID > lastReadMessage.packetID { self.setMessageAsRead(message) }
            } else {
                self.setMessageAsRead(message)
            }
        }
    }

    func gapWasShown(_ gap: MessagesGap) {
        self.historyLoader.loadHistoryFor(gap: gap, chatID: self.chatID) { parsingResult, _ in
            if let parsingResult = parsingResult {
                self.chat.removeGapsObject(gap)
                self.presenter?.gapsWereDeleted([gap])
                SenderCore.shared().interfaceUpdater.messagesGapsWereRemoved([gap])
                SenderCore.shared().interfaceUpdater.messagesWereUpdated(parsingResult.updatedMessages)
                SenderCore.shared().interfaceUpdater.messagesWereAdded(parsingResult.addedMessages)
                SenderCore.shared().interfaceUpdater.messagesGapsWereAdded(parsingResult.addedGaps)
            }
        }
    }

    fileprivate func setMessageAsRead(_ message: Message) {
        guard !message.owner,
              let messageChatID = message.dialog.chatID,
              messageChatID == self.chatID else { return }
        self.readSender.sendReadFor(message: message)
        self.lastReadMessage = message
    }

    func type() {
        self.dataManager.sendTypingTo(chat: self.chat)
    }

    func callContact() {
        let phone = self.chat.getPhoneFormatted(false)
        guard !phone.isEmpty else { return }
        var formattedPhone = phone.replacingOccurrences(of: " ", with: "")
        if !formattedPhone.hasPrefix("+") { formattedPhone = "+" + formattedPhone }
        self.callPhone(formattedPhone)
    }

    func handleSendBarActions(_ actions: [[String: Any]]) {
        let actionsParser = SendBarActionParser()
        for action in actions.flatMap(actionsParser.parseActionDictionary) {
            switch action {
            case .vibro: self.sendVibroMessage()
            case .twitch: self.sendTwitchMessage()
            case .sendMedia(let mediaType): self.sendMediaMessageOf(type: mediaType)
            case .addMember: self.presenter?.addMembersToChat()
            case .scanQR: self.scanQRAndSendToServer()
            case .goTo(let details): break
            case .openURL(let url): self.openURL(url)
            case .callPhone(let phone): self.callPhone(phone)
            case .requestRobot(let details): self.requestRobotWith(robotDictionary: details)
            }
        }
    }

    func sendMediaMessageOf(type: ChatMediaType) {
        switch type {
        case .photo: self.presenter?.takePhoto()
        case .video: self.presenter?.takeVideo()
        case .location: self.presenter?.getLocation()
        }
    }

    func sendMessageWith(text: String) {
        self.messagesSender.sendTextMessageWith(text: text,
                                                toChat: self.chat,
                                                encryptionEnabled: self.chat.isEncrypted(),
                                                completion: nil)
    }

    func sendStickerWith(stickerID: String) {
        self.messagesSender.sendStickerMessageWith(stickerID: stickerID, toChat: self.chat, completion: nil)
    }

    func sendAudioMessageWith(data: Data) {
        self.messagesSender.sendAudioMessageWith(audioData: data, toChat: self.chat, completion: nil)
    }

    func sendVibroMessage() {
        self.messagesSender.sendVibroMessageTo(chat: self.chat, completion: nil)
    }

    func sendVideoWith(assetID: String?, data: Data?, duration: TimeInterval) {
        self.messagesSender.sendVideoMessageTo(chat: self.chat,
                                               videoData: data,
                                               assetID: assetID,
                                               duration: duration,
                                               completion: nil)
    }

    func sendImageWith(assetID: String?, image: UIKit.UIImage?) {
        self.messagesSender.sendImageMessageTo(chat: chat, assetID: assetID, image: image, completion: nil)
    }

    func sendTwitchMessage() {
        let robotModel = CallRobotModel(classString: ".alert.sender")
        self.callRobot(robotModel)
    }

    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?) {
        self.messagesSender.sendLocationMessageTo(chat: self.chat,
                                                  withLocation: location,
                                                  description: description,
                                                  image: image,
                                                  completion: nil)
    }

    func editTextMessage(_ message: Message, withText text: String) {
        self.messagesSender.editTextMessage(message, withText: text, completion: nil)
    }

    func deleteTextMessage(_ message: Message) {
        self.messagesSender.deleteTextMessage(message, completion: nil)
    }

    func openURL(_ url: URL) {
        SenderCore.shared().application.openURL(url)
    }

    func callPhone(_ phone: String) {
        let phoneURLString = "telprompt://" + phone
        guard let phoneUrl = URL(string: phoneURLString) else { return }
        SenderCore.shared().application.openURL(phoneUrl)
    }

    func requestRobotWith(robotDictionary: [AnyHashable: Any]) {
        guard let robotModel = CallRobotModel(actionDictionary: robotDictionary) else { return }
        self.callRobot(robotModel)
    }

    func openImageFrom(message: Message) {
        message.isLoadingFile = true
        self.presenter?.messagesWereUpdated([message])
        self.messageFileManager.loadImageFor(message: message) { image, error in
            message.isLoadingFile = false
            self.presenter?.messagesWereUpdated([message])
            guard error == nil, let image = image else {
                let localizedDescription = SenderFrameworkLocalizedString("load_image_err")
                let imageError = NSError(domain: "Cannot load image",
                                         code: 666,
                                         userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                self.presenter?.showMediaError(imageError)
                return
            }
            self.presenter?.showImage(image)
        }
    }

    func openVideoFrom(message: Message) {
        message.isLoadingFile = true
        self.presenter?.messagesWereUpdated([message])
        self.messageFileManager.loadVideoFor(message: message) { videoURL, error in
            message.isLoadingFile = false
            self.presenter?.messagesWereUpdated([message])
            guard error == nil, let videoURL = videoURL else {
                let localizedDescription = SenderFrameworkLocalizedString("load_video_err")
                let imageError = NSError(domain: "Cannot load video",
                                         code: 666,
                                         userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                self.presenter?.showMediaError(imageError)
                return
            }
            self.presenter?.showVideoWith(url: videoURL)
        }
    }

    func openLocationFrom(message: Message) {
        let locationDictionary = ParamsFacade.sharedInstance().dictionary(from: message.data ?? message.modelData)
        guard let latitude = locationDictionary?["lat"] as? Double,
              let longitude = locationDictionary?["lon"] as? Double else {
            let localizedDescription = SenderFrameworkLocalizedString("load_location_err")
            let imageError = NSError(domain: "Cannot open location video",
                                     code: 666,
                                     userInfo: [NSLocalizedDescriptionKey: localizedDescription])
            self.presenter?.showMediaError(imageError)
            return
        }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.presenter?.showLocation(location)
    }

    func openFileFrom(message: Message) {
        if !message.isLoadingFile {
            message.isLoadingFile = true
            self.presenter?.messagesWereUpdated([message])
        }
        self.messageFileManager.loadFileFor(message: message) { fileURL, error in
            if message.isLoadingFile {
                message.isLoadingFile = false
                self.presenter?.messagesWereUpdated([message])
            }
            guard error == nil, let fileURL = fileURL else {
                let localizedDescription = SenderFrameworkLocalizedString("load_file_err")
                let imageError = NSError(domain: "Cannot load file",
                                         code: 666,
                                         userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                self.presenter?.showMediaError(imageError)
                return
            }
            self.presenter?.openFileWith(url: fileURL)
        }
    }

    func areChatSettingsAvailable() -> Bool {
        return !(chat.isGroup && (chat.chatState == .inactive || chat.chatState == .removed))
    }

    func saveUnsentText(_ unsentText: String?, forChat chat: Dialog) {
        chat.unsentText = unsentText
    }
}

extension ChatInteractor {
    func playAudioFrom(message: Message) {
        self.loadAudioFor(message: message) { audioURL, error in
            guard error == nil, let audioURL = audioURL else {
                let localizedDescription = SenderFrameworkLocalizedString("load_audio_err")
                let imageError = NSError(domain: "Cannot load audio",
                                         code: 666,
                                         userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                self.presenter?.showMediaError(imageError)
                return
            }
            self.playAudioWith(audioURL: audioURL, message: message)
        }
    }

    func loadAudioFor(message: Message, completion: ((URL?, Error?) -> Void)?) {
        if !message.isLoadingFile {
            message.isLoadingFile = true
            self.presenter?.messagesWereUpdated([message])
        }
        self.audioMessagesLoader.loadAudioFor(message: message) { audioURL, error in
            if message.isLoadingFile {
                message.isLoadingFile = false
                self.presenter?.messagesWereUpdated([message])
            }
            completion?(audioURL, error)
        }
    }

    func subscribeToNotificationsOf(audioPlayer: AudioPlayer) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioPlayerDidPlayNotification(_:)),
                                               name: .MWAudioPlayerDidPlay,
                                               object: audioPlayer)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioPlayerProgressChangeNotification(_:)),
                                               name: .MWAudioPlayerProgressChanged,
                                               object: audioPlayer)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioPlayerDidStopNotification(_:)),
                                               name: .MWAudioPlayerDidStop,
                                               object: audioPlayer)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioPlayerDidPauseNotification(_:)),
                                               name: .MWAudioPlayerDidPause,
                                               object: audioPlayer)
    }

    func unsubscribeFromNotificationsOf(audioPlayer: AudioPlayer) {
        NotificationCenter.default.removeObserver(self, name: .MWAudioPlayerDidPlay, object: audioPlayer)
        NotificationCenter.default.removeObserver(self, name: .MWAudioPlayerProgressChanged, object: audioPlayer)
        NotificationCenter.default.removeObserver(self, name: .MWAudioPlayerDidStop, object: audioPlayer)
        NotificationCenter.default.removeObserver(self, name: .MWAudioPlayerDidPause, object: audioPlayer)
    }

    func playAudioWith(audioURL: URL, message: Message) {
        let audioPlayer: AudioMessagePlayer?

        if let existingAudioPlayer = self.audioPlayer,
           let existingPlayerURL = existingAudioPlayer.url,
           existingPlayerURL == audioURL,
           existingAudioPlayer.playingMessage == message {
            audioPlayer = existingAudioPlayer
        } else {
            if let oldAudioPlayer = self.audioPlayer {
                oldAudioPlayer.stop()
                self.unsubscribeFromNotificationsOf(audioPlayer: oldAudioPlayer)
            }
            do {
                let newAudioPlayer = try AudioMessagePlayer(messageToPlay: message, audioURL: audioURL)
                self.subscribeToNotificationsOf(audioPlayer: newAudioPlayer)
                audioPlayer = newAudioPlayer
                self.audioPlayer = audioPlayer
            } catch {
                audioPlayer = nil
            }
        }

        audioPlayer?.play()
    }

    func pauseAudioFrom(message: Message) {
        guard let audioPlayer = self.audioPlayer, audioPlayer.playingMessage == message else { return }
        audioPlayer.pause()
    }

    @objc func audioPlayerProgressChangeNotification(_ notification: Notification) {
        guard let audioPlayer = notification.object as? AudioMessagePlayer else { return }
        let playingMessage = audioPlayer.playingMessage
        let playbackUpdate = AudioMessagePlayback(playingMessage: playingMessage,
                                                  isPlaying: audioPlayer.isPlaying,
                                                  playTime: audioPlayer.currentTime,
                                                  audioDuration: audioPlayer.duration)
        self.presenter?.handleAudioMessagePlaybackUpdate(playbackUpdate)
    }

    @objc func audioPlayerDidStopNotification(_ notification: Notification) {
        guard let audioPlayer = notification.object as? AudioMessagePlayer else { return }
        let playingMessage = audioPlayer.playingMessage
        let playbackUpdate = AudioMessagePlayback(playingMessage: playingMessage, isPlaying: false)
        self.presenter?.handleAudioMessagePlaybackUpdate(playbackUpdate)
        self.audioPlayer = nil
    }

    @objc func audioPlayerDidPlayNotification(_ notification: Notification) {
        guard let audioPlayer = notification.object as? AudioMessagePlayer else { return }
        let playingMessage = audioPlayer.playingMessage
        let playbackUpdate = AudioMessagePlayback(playingMessage: playingMessage,
                                                  isPlaying: true,
                                                  playTime: audioPlayer.currentTime,
                                                  audioDuration: audioPlayer.duration)
        self.presenter?.handleAudioMessagePlaybackUpdate(playbackUpdate)
    }

    @objc func audioPlayerDidPauseNotification(_ notification: Notification) {
        guard let audioPlayer = notification.object as? AudioMessagePlayer else { return }
        let playingMessage = audioPlayer.playingMessage
        let playbackUpdate = AudioMessagePlayback(playingMessage: playingMessage,
                                                  isPlaying: false,
                                                  playTime: audioPlayer.currentTime,
                                                  audioDuration: audioPlayer.duration)
        self.presenter?.handleAudioMessagePlaybackUpdate(playbackUpdate)
    }
}

extension ChatInteractor: FMLActionsHandlerInteractorDelegate {
    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     needsUpdatedChatWithID chatID: String) {
        self.updateWith(chatID: chatID)
    }

    func fmlActionsHandlerInteractor(_ fmlActionsHandlerInteractor: FMLActionsHandlerInteractor,
                                     shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool {
        return true
    }
}

class BitSignManager {
    func signWithOldKey(oldKey: String, publicKey: String) -> String? {
        guard let ownerKey = try? CoreDataFacade.sharedInstance().getOwner().getMainWallet().base58PublicKey,
              let ownerKeyData = BTCDataFromBase58(ownerKey),
              let publicKeyData = BTCDataFromBase58(publicKey),
              publicKeyData.length >= 32 else {
            return nil
        }
        guard let decryptedKey = ECCWorker.shared().eciesDecriptMEssage(oldKey,
                                                                        withPubKeyData: ownerKeyData as Data,
                                                                        shortkEkm: true,
                                                                        usePubKey: false), !decryptedKey.isEmpty else {
            return nil
        }
        return ECCWorker.shared().eciesEncriptMEssage(oldKey,
                                                      withPubKeyData: ownerKeyData as Data,
                                                      shortkEkm: true,
                                                      usePubKey: false)
    }
}
