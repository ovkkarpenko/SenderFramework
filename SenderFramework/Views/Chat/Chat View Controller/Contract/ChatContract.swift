//
// Created by Roman Serga on 5/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol ChatViewProtocol: class {
    var presenter: ChatPresenterProtocol? { get set }
    var fmlActionsHandlerView: FMLActionsHandlerViewProtocol { get set }

    func chatWasUpdated(chat: ChatInfoViewModelProtocol)
    func messagesWereChanged(messagesChanges: [ChatMessagesViewModelChange],
                             newMessagesModel: ChatMessagesViewModelProtocol)
    func messagesWereSet(newMessagesModel: ChatMessagesViewModelProtocol)
    func typingMessageChanged(newChat: ChatInfoViewModelProtocol)
    func showMediaPickerFor(mediaType: ChatMediaType)

    func showInfoWithText(_ infoText: String)
    func showErrorWithText(_ errorText: String)

    func finishLoadingTopHistory()

    func showImage(_ image: UIImage)
    func showVideoWith(url: URL)
    func showLocation(_ location: CLLocation)
    func openFileWith(url: URL)

    func handleAudioMessagePlaybackUpdate(_ playbackUpdate: AudioMessagePlaybackViewModel)

    func handleSendBarDisabledValue(sendBarDisabled: Bool)
    func handleExternalSendBarActions(_ actions: [[String: Any]])

    func setUnsentText(_ unsentText: String?)
}

@objc public protocol ChatModuleDelegate: class {
    func chatModuleDidFinish()
}

protocol ChatPresenterProtocol: class,
                                ChatSettingsModuleDelegate,
                                AddToChatModuleDelegate,
                                QRScannerModuleDelegate,
                                QRDisplayModuleDelegate {
    weak var view: ChatViewProtocol? { get set }
    weak var delegate: ChatModuleDelegate? { get set }
    var router: ChatRouterProtocol? { get set }
    var interactor: ChatInteractorProtocol { get set }

    var fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol { get set }

    func viewWasLoaded()
    func viewDidAppear()
    func viewDidDisappear()
    func viewDidShowMessage(_ message: AbstractMessageViewModel)

    func chatWasUpdated(_ updatedChat: Dialog)
    func chatWasChanged(_ newChat: Dialog)

    func messagesWereSet(_ messages: [Message], gaps: [MessagesGap])
    func messagesWereUpdated(_ updatedMessages: [Message])
    func messagesWereAdded(_ addedMessages: [Message])
    func messagesWereDeleted(_ deletedMessages: [Message])

    func gapsWereAdded(_ addedGaps: [MessagesGap])
    func gapsWereDeleted(_ deletedGaps: [MessagesGap])

    func typingUsersWereChanged(newTypingUsers: [Contact])

    func callContact()
    func openChatSettings()
    func closeChatSettings()
    func addMembersToChat()

    func showQRScanner(completion: @escaping (String?) -> Void)

    func showQRCodeWith(string: String)

    func takePhoto()
    func takeVideo()
    func getLocation()

    func type()
    func handleSendBarActions(_ actions: [[String: Any]])

    func sendMessageWith(text: String)
    func sendStickerWith(stickerID: String)
    func sendAudioMessageWith(data: Data)
    func sendImageWith(assetID: String?, image: UIKit.UIImage?)
    func sendVideoWith(assetID: String?, data: Data?, duration: TimeInterval)
    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?)

    func editTextMessage(_ message: TextMessageViewModel, withText text: String)
    func deleteTextMessage(_ message: TextMessageViewModel)

    func textWasCopiedToClipboard()

    func loadTopHistory()

    func finishLoadingTopHistory()

    func closeChat()

    func showImageFrom(message: ImageMessageViewModel)
    func showImage(_ image: UIImage)
    func showMediaError(_ error: Error)

    func showVideoFrom(message: VideoMessageViewModel)
    func showVideoWith(url: URL)

    func showLocationFrom(message: LocationMessageViewModel)
    func showLocation(_ location: CLLocation)

    func playAudioFrom(message: AudioMessageViewModel)
    func pauseAudioFrom(message: AudioMessageViewModel)

    func openFileFrom(message: FileMessageViewModel)
    func openFileWith(url: URL)

    func handleAudioMessagePlaybackUpdate(_ playbackUpdate: AudioMessagePlayback)

    func handleSendBarDisabledValue(sendBarDisabled: Bool)

    func handleExternalSendBarActions(_ actions: [[String: Any]])

    func openChatFrom(message: AbstractMessageViewModel)

    func saveSendBarText(_ sendBarText: String?, forChat chat: ChatInfoViewModelProtocol)
    func setUnsentText(_ unsentText: String?)
}

protocol ChatRouterProtocol: class {
    weak var presenter: ChatPresenterProtocol? { get set }

    var fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol { get set }

    func presentViewWith(wireframe: ViewControllerWireframe,
                         model: ChatPresentationModelProtocol,
                         forDelegate delegate: ChatModuleDelegate?,
                         completion: (() -> Void)?)
    func dismissView(completion: (() -> Void)?)
    func dismissAllViews(completion: (() -> Void)?)

    func showCallScreen()

    func showChatSettingsWith(chat: Dialog)
    func dismissChatSettings()

    func presentAddMemberScreen()
    func dismissAddMemberScreen()

    func presentQRScanner()
    func dismissQRScanner()

    func presentQRCodeWith(string: String)
    func dismissQRCode()

    func openChatScreenWith(chat: Dialog)
}

@objc public class ChatPresentationModelOption: NSObject {
    public static let hideSendBar = "ChatPresentationModelOptionHideSendBar"
}

@objc public protocol ChatPresentationModelProtocol {
    var chatID: String { get }
    var chat: Dialog? { get }
    var actions: [[String: Any]]? { get set }
    var options: [String: Any]? { get set }
}

public enum ChatMediaType {
    case photo
    case video
    case location
}

@objc(MWGoogleUser)
/*
    Swift name also has prefix, because otherwise obj-c methods that use MWGoogleUser are not visible to Swift
*/
public class MWGoogleUser: NSObject {
    let accessToken: String?
    let userID: String?
    let idToken: String?
    let fullName: String?
    let givenName: String?
    let familyName: String?
    let email: String?

    init (accessToken: String?,
          userID: String?,
          idToken: String?,
          fullName: String?,
          givenName: String?,
          familyName: String?,
          email: String?) {
        self.accessToken = accessToken
        self.userID = userID
        self.idToken = idToken
        self.fullName = fullName
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
    }
}

public class AudioMessagePlaybackViewModel {
    let audioMessage: AudioMessageViewModel
    let playTime: TimeInterval?
    let audioDuration: TimeInterval?
    let isPlaying: Bool

    init(audioMessage: AudioMessageViewModel,
         isPlaying: Bool,
         playTime: TimeInterval? = nil,
         audioDuration: TimeInterval? = nil) {
        self.audioMessage = audioMessage
        self.playTime = playTime
        self.audioDuration = audioDuration
        self.isPlaying = isPlaying
    }

    var progress: Double {
        guard let playTime = self.playTime, let audioDuration = self.audioDuration else { return -1.0 }
        return playTime / audioDuration
    }
}

public class AudioMessagePlayback {
    let playingMessage: Message
    let playTime: TimeInterval?
    let audioDuration: TimeInterval?
    let isPlaying: Bool

    init(playingMessage: Message,
         isPlaying: Bool,
         playTime: TimeInterval? = nil,
         audioDuration: TimeInterval? = nil) {
        self.playingMessage = playingMessage
        self.playTime = playTime
        self.audioDuration = audioDuration
        self.isPlaying = isPlaying
    }
}

protocol ChatInteractorProtocol: Chat,
                                 MessagesChangesHandler,
                                 ChatsChangesHandler,
                                 MessagesGapsChangesHandler,
                                 TypingChangesHandler {
    var chat: Dialog! { get set }
    var chatID: String! { get set }
    weak var presenter: ChatPresenterProtocol? { get set }

    var sendBarDisabled: Bool { get set }
    var sendBarActions: [[String: Any]]? { get set }

    var isActive: Bool { get set }

    var fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol { get set }

    func loadData()
    func setActiveState(_ activeState: Bool)

    func updateWith(chat: Dialog)
    func updateWith(chatID: String)

    func callRobot(_ callRobotModel: CallRobotModel)

    func messageWasShown(_ message: Message)
    func gapWasShown(_ gap: MessagesGap)

    func type()

    func handleSendBarActions(_ actions: [[String: Any]])

    func sendMessageWith(text: String)
    func sendStickerWith(stickerID: String)
    func sendAudioMessageWith(data: Data)
    func sendImageWith(assetID: String?, image: UIKit.UIImage?)
    func sendVideoWith(assetID: String?, data: Data?, duration: TimeInterval)
    func sendLocation(_ location: CLLocation, withImage image: UIKit.UIImage?, description: String?)

    func editTextMessage(_ message: Message, withText text: String)
    func deleteTextMessage(_ message: Message)

    func callContact()

    func loadTopHistory()

    func openImageFrom(message: Message)
    func openVideoFrom(message: Message)
    func openLocationFrom(message: Message)
    func playAudioFrom(message: Message)
    func pauseAudioFrom(message: Message)
    func openFileFrom(message: Message)

    func areChatSettingsAvailable() -> Bool
    func saveUnsentText(_ unsentText: String?, forChat chat: Dialog)
}

public protocol ChatDataManagerProtocol {
    func getSenderUsers() -> [Contact]
    func getContacts() -> [Contact]

    func chatWith(chatID: String) -> Dialog
    func callRobotWith(model: CallRobotModelProtocol, completion: (([AnyHashable: Any]?, Error?) -> Void)?)
    func sendQRString(_ qrString: String, chatID: String, completion: ((Bool, Error?) -> Void)?)

    func startMessagesChangesObservingWith(messagesChangesHandler: MessagesChangesHandler)
    func stopMessagesChangesObserving()

    func startChatChangesObservingWith(chatChangesHandler: ChatsChangesHandler)
    func stopChatChangesObserving()

    func startTypingObservingWith(typingChangesHandler: TypingChangesHandler)
    func stopTypingChangesObserving()

    func startMessagesGapsChangesObservingWith(messagesGapsChangesHandler: MessagesGapsChangesHandler)
    func stopMessagesGapsChangesObserving()

    func loadHistoryWith(chatID: String,
                         topPacketID: Int,
                         messagesCount: UInt,
                         completion: ((MessagesParsingResult?, Error?) -> Void)?)

    func loadHistoryWith(chatID: String,
                         startPacketID: Int,
                         endPacketID: Int,
                         completion: ((MessagesParsingResult?, Error?) -> Void)?)

    func sendReadFor(message: Message)

    func update(chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)

    func sendTypingTo(chat: Dialog)

    func sendFormData(_ formData: [AnyHashable: Any], completion: ((Bool, Error?) -> Void)?)

    func changeFullVersionStateTo(newFullVersionState: Bool, completion: ((Bool, Error?) -> Void)?)

    func uploadData(_ data: Data, completion: ((URL?, Error?) -> Void)?)

    func getOwnerBitcoinWallet() -> BitcoinWallet?

    func requestOnlineStatusFor(contact: Contact)
}

public protocol MessageSenderProtocol {
    typealias MessageManagerCompletion = ((Message?, Error?) -> Void)

    func sendTextMessageWith(text: String,
                             toChat chat: Dialog,
                             encryptionEnabled: Bool,
                             completion: MessageManagerCompletion?)
    func sendStickerMessageWith(stickerID: String, toChat chat: Dialog, completion: MessageManagerCompletion?)
    func sendAudioMessageWith(audioData: Data, toChat chat: Dialog, completion: MessageManagerCompletion?)
    func sendVibroMessageTo(chat: Dialog, completion: MessageManagerCompletion?)
    func sendImageMessageTo(chat: Dialog,
                            assetID: String?,
                            image: UIKit.UIImage?,
                            completion: MessageManagerCompletion?)
    func sendVideoMessageTo(chat: Dialog,
                            videoData: Data?,
                            assetID: String?,
                            duration: TimeInterval,
                            completion: MessageManagerCompletion?)
    func sendLocationMessageTo(chat: Dialog,
                               withLocation location: CLLocation,
                               description: String?,
                               image: UIKit.UIImage?,
                               completion: MessageManagerCompletion?)
    func editTextMessage(_ textMessage: Message, withText text: String, completion: MessageManagerCompletion?)
    func deleteTextMessage(_ textMessage: Message, completion: MessageManagerCompletion?)
}

@objc public protocol ChatModuleProtocol {
    func presentWith(wireframe: ViewControllerWireframe,
                     model: ChatPresentationModelProtocol,
                     forDelegate delegate: ChatModuleDelegate?,
                     completion: (() -> Void)?)
    func dismissWithChildModules(completion: (() -> Void)?)
    func dismiss(completion: (() -> Void)?)
}

public protocol GoogleUserManagerProtocol {
    func saveGoogleUser(_ googleUser: MWGoogleUser, completion: ((Bool, Error?) -> Void)?)
}
