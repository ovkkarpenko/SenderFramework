//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatPresenter: ChatPresenterProtocol {
    weak var view: ChatViewProtocol?
    weak var delegate: ChatModuleDelegate?
    var router: ChatRouterProtocol?
    var interactor: ChatInteractorProtocol

    var chatInfo: ChatInfoViewModel!
    var chatMessages: ChatMessagesViewModel!

    var fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol

    init(interactor: ChatInteractorProtocol,
         fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol,
         router: ChatRouterProtocol?) {
        self.interactor = interactor
        self.fmlActionsHandlerPresenter = fmlActionsHandlerPresenter
        self.router = router
    }

    func callContact() {
        self.interactor.callContact()
    }

    func openChatSettings() {
        if self.interactor.areChatSettingsAvailable() {
            self.router?.showChatSettingsWith(chat: self.interactor.chat)
        }
    }

    func closeChatSettings() {
        self.router?.dismissChatSettings()
    }

    func viewWasLoaded() {
        self.interactor.loadData()
    }

    func viewDidAppear() {
        self.interactor.setActiveState(true)
    }

    func viewDidDisappear() {
        self.interactor.setActiveState(false)
    }

    func viewDidShowMessage(_ message: AbstractMessageViewModel) {
        if let messageViewModel = message as? MessageViewModel {
            self.interactor.messageWasShown(messageViewModel.message)
        } else if let gapViewModel = message as? GapMessageViewModel {
            self.interactor.gapWasShown(gapViewModel.gap)
        }
    }

    func chatSettingsModuleDidUpdateChat(_ chat: Dialog) {
        if chat.chatID != self.interactor.chatID { self.router?.dismissChatSettings() }
        self.interactor.updateWith(chat: chat)
    }

    func chatSettingsModule(_ chatSettingsModule: ChatSettingsModuleProtocol,
                            shouldCallRobotWithModel callRobotModel: CallRobotModel) -> Bool {
        self.interactor.callRobot(callRobotModel)
        self.router?.dismissChatSettings()
        return false
    }

    func chatSettingsModule(_ chatSettingsModule: ChatSettingsModuleProtocol,
                            shouldOpenChat chat: Dialog,
                            withActions actions: [[String: AnyObject]]?) -> Bool {
        guard chat.chatID == self.interactor.chatID else { return true }
        self.interactor.updateWith(chat: chat)
        if let actions = actions { self.view?.handleExternalSendBarActions(actions) }
        self.router?.dismissChatSettings()
        return false
    }

    func chatSettingsModuleDidFinish(_ chatSettingsModule: ChatSettingsModuleProtocol) {
        self.router?.dismissChatSettings()
    }

    func chatWasUpdated(_ updatedChat: Dialog) {
        self.chatInfo?.updateWith(chat: updatedChat)
        if let chatViewModel = self.chatInfo {
            self.view?.chatWasUpdated(chat: chatViewModel)
        }
    }

    func chatWasChanged(_ newChat: Dialog) {
        self.chatInfo = ChatInfoViewModel(chat: newChat)
        self.view?.chatWasUpdated(chat: self.chatInfo)
    }

    func messagesWereSet(_ messages: [Message], gaps: [MessagesGap]) {
        self.chatMessages = ChatMessagesViewModel(messages: messages, gaps: gaps)
        self.view?.messagesWereSet(newMessagesModel: self.chatMessages)
    }

    func messagesWereUpdated(_ updatedMessages: [Message]) {
        let messagesChanges = self.chatMessages.updateMessages(updatedMessages)
        self.view?.messagesWereChanged(messagesChanges: messagesChanges, newMessagesModel: self.chatMessages)
    }

    func messagesWereAdded(_ addedMessages: [Message]) {
        let messagesChanges = self.chatMessages.addMessages(addedMessages)
        self.view?.messagesWereChanged(messagesChanges: messagesChanges, newMessagesModel: self.chatMessages)
    }

    func messagesWereDeleted(_ deletedMessages: [Message]) {
        let messagesChanges = self.chatMessages.removeMessages(deletedMessages)
        self.view?.messagesWereChanged(messagesChanges: messagesChanges, newMessagesModel: self.chatMessages)
    }

    func gapsWereAdded(_ addedGaps: [MessagesGap]) {
        let messagesChanges = self.chatMessages.addGaps(addedGaps)
        self.view?.messagesWereChanged(messagesChanges: messagesChanges, newMessagesModel: self.chatMessages)
    }

    func gapsWereDeleted(_ deletedGaps: [MessagesGap]) {
        let messagesChanges = self.chatMessages.removeGaps(deletedGaps)
        self.view?.messagesWereChanged(messagesChanges: messagesChanges, newMessagesModel: self.chatMessages)
    }

    func addToChatModuleDidFinishWith(newChat: Dialog, selectedEntities: [EntityViewModel]) {
        self.interactor.updateWith(chat: newChat)
        self.router?.dismissAddMemberScreen()
    }

    func addMembersToChat() {
        self.router?.presentAddMemberScreen()
    }

    func typingUsersWereChanged(newTypingUsers: [Contact]) {
        _ = self.chatInfo.changeTypingUsers(newTypingUsers: newTypingUsers)
        self.view?.typingMessageChanged(newChat: self.chatInfo)
    }

    func entityPickerModuleDidCancel() {
        self.router?.dismissAddMemberScreen()
    }

    func entityPickerModuleDidFinishWith(entities: [EntityViewModel]) {
        self.router?.dismissAddMemberScreen()
    }

    var qrScannerCompletion: ((String?) -> Void)?

    func showQRScanner(completion: @escaping (String?) -> Void) {
        self.qrScannerCompletion = completion
        self.router?.presentQRScanner()
    }

    func qrScannerModuleDidCancel() {
        self.qrScannerCompletion?(nil)
        self.router?.dismissQRScanner()
        self.qrScannerCompletion = nil
    }

    func qrScannerModuleDidFinishWith(string: String) {
        self.qrScannerCompletion?(string)
        self.router?.dismissQRScanner()
        self.qrScannerCompletion = nil
    }

    func showQRCodeWith(string: String) {
        self.router?.presentQRCodeWith(string: string)
    }

    func qrDisplayModuleDidCancel() {
        self.router?.dismissQRCode()
    }

    func takePhoto() {
        self.view?.showMediaPickerFor(mediaType: .photo)
    }

    func takeVideo() {
        self.view?.showMediaPickerFor(mediaType: .video)
    }

    func getLocation() {
        self.view?.showMediaPickerFor(mediaType: .location)
    }

    func type() {
        self.interactor.type()
    }

    func handleSendBarActions(_ actions: [[String: Any]]) {
        self.interactor.handleSendBarActions(actions)
    }

    func sendMessageWith(text: String) {
        self.interactor.sendMessageWith(text: text)
    }

    func editTextMessage(_ message: TextMessageViewModel, withText text: String) {
        self.interactor.editTextMessage(message.message, withText: text)
    }

    func deleteTextMessage(_ message: TextMessageViewModel) {
        self.interactor.deleteTextMessage(message.message)
    }

    func sendStickerWith(stickerID: String) {
        self.interactor.sendStickerWith(stickerID: stickerID)
    }

    func sendAudioMessageWith(data: Data) {
        self.interactor.sendAudioMessageWith(data: data)
    }

    func sendImageWith(assetID: String?, image: UIKit.UIImage?) {
        self.interactor.sendImageWith(assetID: assetID, image: image)
    }

    func sendVideoWith(assetID: String?, data: Data?, duration: TimeInterval) {
        self.interactor.sendVideoWith(assetID: assetID, data: data, duration: duration)
    }

    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?) {
        self.interactor.sendLocation(location, withImage: image, description: description)
    }

    func textWasCopiedToClipboard() {
        let infoText = SenderFrameworkLocalizedString("fml_text_was_copied")
        self.view?.showInfoWithText(infoText)
    }

    func loadTopHistory() {
        self.interactor.loadTopHistory()
    }

    func finishLoadingTopHistory() {
        self.view?.finishLoadingTopHistory()
    }

    func closeChat() {
        self.delegate?.chatModuleDidFinish()
    }

    func showImageFrom(message: ImageMessageViewModel) {
        self.interactor.openImageFrom(message: message.message)
    }

    func showImage(_ image: UIImage) {
        self.view?.showImage(image)
    }

    func showMediaError(_ error: Error) {
        self.view?.showErrorWithText(error.localizedDescription)
    }

    func showVideoFrom(message: VideoMessageViewModel) {
        self.interactor.openVideoFrom(message: message.message)
    }

    func showVideoWith(url: URL) {
        self.view?.showVideoWith(url: url)
    }

    func showLocationFrom(message: LocationMessageViewModel) {
        self.interactor.openLocationFrom(message: message.message)
    }

    func showLocation(_ location: CLLocation) {
        self.view?.showLocation(location)
    }

    func playAudioFrom(message: AudioMessageViewModel) {
        self.interactor.playAudioFrom(message: message.message)
    }

    func pauseAudioFrom(message: AudioMessageViewModel) {
        self.interactor.pauseAudioFrom(message: message.message)
    }

    func handleAudioMessagePlaybackUpdate(_ playbackUpdate: AudioMessagePlayback) {
        let message = playbackUpdate.playingMessage
        guard let viewModel = self.chatMessages.messageViewModelFor(message: message) as? AudioMessageViewModel else {
            return
        }
        let playbackUpdateViewModel = AudioMessagePlaybackViewModel(audioMessage: viewModel,
                                                                    isPlaying: playbackUpdate.isPlaying,
                                                                    playTime: playbackUpdate.playTime,
                                                                    audioDuration: playbackUpdate.audioDuration)
        self.view?.handleAudioMessagePlaybackUpdate(playbackUpdateViewModel)
    }

    func openFileFrom(message: FileMessageViewModel) {
        self.interactor.openFileFrom(message: message.message)
    }

    func openFileWith(url: URL) {
        self.view?.openFileWith(url: url)
    }

    func handleSendBarDisabledValue(sendBarDisabled: Bool) {
        self.view?.handleSendBarDisabledValue(sendBarDisabled: sendBarDisabled)
    }

    func handleExternalSendBarActions(_ actions: [[String: Any]]) {
        self.view?.handleExternalSendBarActions(actions)
    }

    func openChatFrom(message: AbstractMessageViewModel) {
        guard let message = message as? MessageViewModel,
              let p2pChat = message.message.authorContact?.p2pChat,
              p2pChat.chatID != self.interactor.chatID else { return }
        self.router?.openChatScreenWith(chat: p2pChat)
    }

    func setUnsentText(_ unsentText: String?) {
        self.view?.setUnsentText(unsentText)
    }

    func saveSendBarText(_ sendBarText: String?, forChat chat: ChatInfoViewModelProtocol) {
        self.interactor.saveUnsentText(sendBarText, forChat: chat.chat)
    }
}
