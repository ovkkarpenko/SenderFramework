//
// Created by Roman Serga on 6/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

protocol MessageViewBuilderProtocol {
    associatedtype MessageViewType: UIView

    func buildMessageWith(viewModel: TextMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: FormMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: StickerMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: ImageMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: VideoMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: AudioMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: LocationMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: FileMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: VibroChatMessageViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: NotificationViewModel, maxWidth: CGFloat) -> MessageViewType
    func buildMessageWith(viewModel: GapMessageViewModel, maxWidth: CGFloat) -> MessageViewType

    func sizeOfMessageViewWith(viewModel: TextMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: FormMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: StickerMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: ImageMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: VideoMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: AudioMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: LocationMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: FileMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: VibroChatMessageViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: NotificationViewModel, maxWidth: CGFloat) -> CGSize
    func sizeOfMessageViewWith(viewModel: GapMessageViewModel, maxWidth: CGFloat) -> CGSize
}

protocol MessageViewBuilderDelegate: class {
    func messageViewBuilder(_ messageViewBuilder: MessageViewBuilder,
                            fmlEventsHandlerFor formViewModel: FormMessageViewModel) -> PBConsoleViewDelegate
}

class BaseMessageLayout {
    var size: CGSize

    init(size: CGSize) {
        self.size = size
    }
}

class MessageWithTimeLayout: BaseMessageLayout {
    var timeIndicatorSize: CGSize

    init(size: CGSize, timeIndicatorSize: CGSize) {
        self.timeIndicatorSize = timeIndicatorSize
        super.init(size: size)
    }
}

class FormMessageLayout: BaseMessageLayout {
    var messageView: PBConsoleView?
}

class MessageViewBuilder: MessageViewBuilderProtocol {
    let cache: MessagesLayoutCache
    weak var delegate: MessageViewBuilderDelegate?

    init(cache: MessagesLayoutCache) {
        self.cache = cache
    }

    var cachedTextMessageViews = [TextMessageView]()

    func buildMessageWith(viewModel: TextMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view: TextMessageView
        if let cachedTextView = self.cachedTextMessageViews.first(where: { $0.superview == nil }) {
            view = cachedTextView
        } else {
            view = TextMessageView()
            self.cachedTextMessageViews.append(view)
        }
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) as? TextMessageViewLayout {
            _ = view.updateWith(textMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(textMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: TextMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = TextMessageView.layoutWith(textMessage: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: FormMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) as? FormMessageLayout
        let formDelegate = self.delegate?.messageViewBuilder(self, fmlEventsHandlerFor: viewModel)
        let messageView: PBConsoleView
        if let cachedMessageView = cachedLayout?.messageView {
            messageView = cachedMessageView
            messageView.delegate = formDelegate
        } else {
            messageView = PBConsoleManager.buildConsoleView(fromDate: viewModel.message,
                                                            maxWidth: maxWidth,
                                                            delegate: formDelegate)
            messageView.layer.shouldRasterize = true
            messageView.layer.rasterizationScale = UIScreen.main.scale
        }

        let layout = FormMessageLayout(size: messageView.frame.size)
        layout.messageView = messageView
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return messageView
    }

    func sizeOfMessageViewWith(viewModel: FormMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let size = PBConsoleManager.buildConsoleView(fromDate: viewModel.message,
                                                     maxWidth: maxWidth,
                                                     delegate: nil).bounds.size
        let layout = BaseMessageLayout(size: size)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return size
    }

    func buildMessageWith(viewModel: StickerMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = StickerMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? StickerMessageViewLayout {
            _ = view.updateWith(stickerMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(stickerMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: StickerMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = StickerMessageView.layoutWith(stickerMessage: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: ImageMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = ImageMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? MediaMessageViewLayout {
            _ = view.updateWith(imageMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(imageMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: ImageMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = ImageMessageView.layoutWith(message: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: VideoMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = VideoMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? MediaMessageViewLayout {
            _ = view.updateWith(videoMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(videoMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: VideoMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = VideoMessageView.layoutWith(message: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: AudioMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = AudioMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? AudioMessageViewLayout {
            _ = view.updateWith(audioMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(audioMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: AudioMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = AudioMessageView.layoutWith(audioMessage: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: LocationMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = LocationMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? MediaMessageViewLayout {
            _ = view.updateWith(locationMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(locationMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: LocationMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = LocationMessageView.layoutWith(message: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: FileMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = FileMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) as? FileMessageViewLayout {
            _ = view.updateWith(fileMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(fileMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: FileMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = FileMessageView.layoutWith(fileMessage: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: VibroChatMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = VibroChatMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? VibroChatMessageViewLayout {
            _ = view.updateWith(vibroChatMessage: viewModel, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(vibroChatMessage: viewModel, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: VibroChatMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = VibroChatMessageView.layoutWith(vibroChatMessage: viewModel, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: NotificationViewModel, maxWidth: CGFloat) -> MessageView {
        let view = NotificationMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? NotificationMessageViewLayout {
            _ = view.updateWith(text: viewModel.notificationText, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(text: viewModel.notificationText, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: NotificationViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = NotificationMessageView.layoutWith(text: viewModel.notificationText, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }

    func buildMessageWith(viewModel: GapMessageViewModel, maxWidth: CGFloat) -> MessageView {
        let view = NotificationMessageView()
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel,
                                                   maxWidth: maxWidth) as? NotificationMessageViewLayout {
            _ = view.updateWith(text: viewModel.gapText, maxWidth: maxWidth, layout: cachedLayout)
            return view
        }
        let layout = view.updateWith(text: viewModel.gapText, maxWidth: maxWidth, layout: nil)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return view
    }

    func sizeOfMessageViewWith(viewModel: GapMessageViewModel, maxWidth: CGFloat) -> CGSize {
        if let cachedLayout = self.cache.layoutFor(keyObject: viewModel, maxWidth: maxWidth) {
            return cachedLayout.size
        }

        let layout = NotificationMessageView.layoutWith(text: viewModel.gapText, maxWidth: maxWidth)
        self.cache.setLayout(layout, forKeyObject: viewModel, maxWidth: maxWidth)
        return layout.size
    }
}
