//
// Created by Roman Serga on 19/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

enum AbstractMessageViewModelAuthor {
    case owner
    case interlocutor
    case system
}

class AbstractMessageViewModel: Equatable {
    var creationTime: Date { fatalError("Don't use AbstractMessageViewModel'properties directly. " +
                                                "Subclasses must override creationTime") }

    fileprivate var _creationTimeDescription: String?

    var creationTimeDescription: String? {
        if _creationTimeDescription == nil {
            _creationTimeDescription = ParamsFacade.sharedInstance().formattedString(from: self.creationTime)
        }
        return _creationTimeDescription
    }

    var messageID: String { fatalError("Don't use AbstractMessageViewModel'properties directly. " +
                                               "Subclasses must override messageID") }

    var isGluedWithPreviousMessage: Bool = false

    var author: AbstractMessageViewModelAuthor { fatalError("Don't use AbstractMessageViewModel'properties directly. " +
                                                                    "Subclasses must override author") }

    public static func == (lhs: AbstractMessageViewModel, rhs: AbstractMessageViewModel) -> Bool {
        return lhs.messageID == rhs.messageID
    }

    public func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> T.MessageViewType {
        fatalError("Don't use AbstractMessageViewModel's buildViewWith method directly. " +
                           "Subclasses must override this method")
    }

    public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        fatalError("Don't use AbstractMessageViewModel's sizeOfViewWith method directly. " +
                           "Subclasses must override this method")
    }

    var isDeleted: Bool { return false }
}

class MessageViewModel: AbstractMessageViewModel {
    override var creationTime: Date { return self.message.created }
    var fromName: String { return self.message.authorName ?? "" }
    var fromID: String { return self.message.fromId ?? "" }
    var fromPhotoURL: URL? { return self.message.authorContact?.p2pChat.parsedImageURL ?? nil }
    var packetID: String { return self.message.packetID }
    var linkID: String { return self.message.linkID }
    override var messageID: String { return self.message.moId ?? "" }
    var isOwner: Bool { return self.message.owner }
    var isEditable: Bool { return false }
    var isEncrypted: Bool { return false }
    var isEdited: Bool { return false }
    override var author: AbstractMessageViewModelAuthor { return self.message.owner ? .owner : .interlocutor }

    private(set) var message: Message

    init(message: Message) {
        self.message = message
    }

    static func == (lhs: MessageViewModel, rhs: MessageViewModel) -> Bool {
        return lhs.messageID == rhs.messageID || lhs.message == rhs.message
    }

    func defaultPhotoWith(size: CGSize, rounded: Bool) -> UIImage? {
        guard let author = self.message.authorContact else { return nil }
        let emoji = author.p2pChat?.defaultImageEmoji ?? author.defaultImageEmoji
        return DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                              size: size,
                                                              rounded: rounded,
                                                              backgroundImageName: "icAccount")
    }
}

class TextMessageViewModel: MessageViewModel {
    override var isEditable: Bool { return self.isOwner && Date() < self.message.editLimit }
    override var isEncrypted: Bool { return self.message.encrypted.boolValue }
    override var isEdited: Bool { return self.message.isEditedMessage }
    override var isDeleted: Bool { return self.message.isDeletedMessage }

    lazy var text: String = {
        let text: String
        if self.isDeleted {
            text = SenderFrameworkLocalizedString("lst_msg_text_for_lc_deleted_ios")
        } else {
            if let messageText = self.message.textMessage {
                text = messageText
            } else {
                text = self.isEncrypted ? SenderFrameworkLocalizedString("lst_msg_text_for_lc_encrypted_text_ios") : ""
            }
        }
        return text
    }()

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class FormMessageViewModel: MessageViewModel {
    override var author: AbstractMessageViewModelAuthor {
        return self.message.robotId != nil && self.message.robotId == "alert" ? super.author : .system
    }
    var data: [AnyHashable: Any]? {
        guard let messageData = self.message.data else { return nil }
        return ParamsFacade.sharedInstance().dictionary(from: messageData)
    }

    var classRef: String { return self.message.classRef }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class StickerMessageViewModel: MessageViewModel {
    private var stickerID: String? {
        guard let messageData = self.message.data else { return nil }
        let stickerDictionary = ParamsFacade.sharedInstance().dictionary(from: messageData)
        return stickerDictionary?["id"] as? String
    }

    var stickerURL: URL? {
        guard let stickerID = self.stickerID else { return nil }
        let urlString = "https://s.sender.mobi/stickers/" + stickerID + ".png"
        return URL(string: urlString)
    }

    var stickerImage: UIImage? {
        guard let stickerID = self.stickerID else { return nil }
        return UIKit.UIImage(fromSenderFrameworkNamed: stickerID)
    }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class MediaMessageViewModel: MessageViewModel {
    var previewURL: URL? {
        /*
            Old messages may have prev_url that represents local file with invalid url.
            We would use only urls that represent remote files.
        */
        let urlString: String?
        if let filePreviewURLString = self.message.file.prev_url, !filePreviewURLString.hasPrefix("/var/") {
            urlString = filePreviewURLString
        } else {
            urlString = self.message.file.url
        }
        guard let urlStringUnwrapped = urlString else { return nil }
        return NSURL.mw_URLByAddingPercentEscapes(to: urlStringUnwrapped) as URL?
    }

    var defaultPreviewText: String {
        return ""
    }

    var isLoadingMedia: Bool { return self.message.isLoadingFile }
}

class ImageMessageViewModel: MediaMessageViewModel {
    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }

    override var defaultPreviewText: String {
        return "📷"
    }
}

class PlayableMediaMessageViewModel: MediaMessageViewModel {
    func getDuration(completion: @escaping (String) -> Void) {
        if let cachedDuration = self.message.file.duration { completion(cachedDuration); return }

        guard let localURLString = self.message.file.localUrl, let localURL = URL(string: localURLString) else {
            completion("--:--")
            return
        }

        let asset = AVURLAsset(url: localURL)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            let assetDuration = asset.duration.seconds
            if assetDuration == 0.0 {
                do {
                    let assetData = try Data(contentsOf: localURL, options: .uncached)
                    if assetData.isEmpty {
                        completion("--:--")
                        return
                    }
                } catch {
                    completion("--:--")
                    return
                }
            }
            let durationFloat = assetDuration / 100.0
            let durationString = String(format: "%.02f", durationFloat)
            DispatchQueue.main.async {
                self.message.file.duration = durationString.replacingOccurrences(of: ".", with: ":")
                completion(self.message.file.duration)
            }
        }
    }
}

class VideoMessageViewModel: PlayableMediaMessageViewModel {
    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }

    override var defaultPreviewText: String {
        return "📹"
    }
}

class AudioMessageViewModel: PlayableMediaMessageViewModel {
    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }

    var assetURL: URL? {
        guard let localURLString = self.message.file.localUrl else { return nil }
        return URL(string: localURLString)
    }
}

class GapMessageViewModel: AbstractMessageViewModel {
    override var creationTime: Date { return self.gap.created }
    override var author: AbstractMessageViewModelAuthor { return .system }
    override var messageID: String {
        return "MessagesGap" + self.gap.startPacketID.stringValue + self.gap.endPacketID.stringValue
    }
    var isActive: Bool = true
    var gap: MessagesGap

    init(gap: MessagesGap) {
        self.gap = gap
    }

    var gapText: String { return SenderFrameworkLocalizedString("loading_msg") }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class LocationMessageViewModel: MessageViewModel {

    private var coordinatesDictionary: [AnyHashable: Any]? {
        guard let messageData = self.message.data ?? self.message.modelData else { return nil }
        return ParamsFacade.sharedInstance().dictionary(from: messageData)
    }

    var latitude: Double {
        return (self.coordinatesDictionary?["lat"] as? Double) ?? 0.0
    }
    var longitude: Double {
        return (self.coordinatesDictionary?["lon"] as? Double) ?? 0.0
    }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class FileMessageViewModel: MessageViewModel {
    var fileName: String { return self.message.file.name }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }

    var isLoadingFile: Bool { return self.message.isLoadingFile }
}

class NotificationViewModel: MessageViewModel {
    override var author: AbstractMessageViewModelAuthor { return .system }

    var notificationText: String {
        if let formattedDate = self.creationTimeDescription {
            return "\(formattedDate) \(self.message.previewText ?? "")"
        } else {
            return self.message.previewText
        }
    }

    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class VibroChatMessageViewModel: MessageViewModel {
    public override func buildViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T,
                                                                      maxWidth: CGFloat) -> T.MessageViewType {
        return viewBuilder.buildMessageWith(viewModel: self, maxWidth: maxWidth)
    }

    override public func sizeOfViewWith<T: MessageViewBuilderProtocol>(viewBuilder: T, maxWidth: CGFloat) -> CGSize {
        return viewBuilder.sizeOfMessageViewWith(viewModel: self, maxWidth: maxWidth)
    }
}

class TypingMessageViewModel {

    var typingUsers: [Contact]

    var typingText: String {
        let names = typingUsers.map({
            return $0.name ?? SenderFrameworkLocalizedString("unknown_user")
        }).joined(separator: ", ")
        return names + " 💬"
    }

    init(typingUsers: [Contact]) {
        self.typingUsers = typingUsers
    }
}
