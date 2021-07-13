//
// Created by Roman Serga on 22/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    func mw_scrollToLastItem(at scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        guard let lastItemIndexPath = self.mw_lastItemIndexPath() else { return }
        self.scrollToItem(at: lastItemIndexPath, at: scrollPosition, animated: animated)
    }

    func mw_scrollToBottomAnimated(_ animated: Bool) {
        let bottomContentOffset: CGFloat
        let contentInset = self.mw_contentInsetWithAdjustments
        if self.mw_isContentHeightBiggerThenCollectionView {
            bottomContentOffset = self.contentSize.height - self.frame.height + self.contentInset.bottom
        } else {
            bottomContentOffset = -contentInset.top
        }
        let newContentOffset = CGPoint(x: CGFloat(0.0), y: bottomContentOffset)
        if newContentOffset != self.contentOffset {
            self.mw_setContentOffsetAndCallDelegate(newContentOffset, animated: animated)
        }
    }

    func mw_lastItemIndexPath() -> IndexPath? {
        guard self.numberOfSections > 0 else { return nil }
        for sectionIndex in stride(from:(self.numberOfSections - 1), to:-1, by:-1) {
            let itemsInSectionCount = self.numberOfItems(inSection: sectionIndex)
            if itemsInSectionCount > 0 {
                return IndexPath(item: itemsInSectionCount - 1, section: sectionIndex)
            }
        }
        return nil
    }

    func mw_isLastItemVisibleWithContentInsets() -> Bool {
        guard let lastItemIndexPath = self.mw_lastItemIndexPath() else { return false }
        return self.mw_isItemVisibleWithContentInsetsAt(indexPath: lastItemIndexPath)
    }

    func mw_isItemVisibleWithContentInsetsAt(indexPath: IndexPath) -> Bool {
        guard let itemAttributes = self.collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
            return false
        }
        let visibleRect = self.mw_visibleRectWithContentInsets
        return visibleRect.intersects(itemAttributes.frame)
    }

    func mw_setContentOffsetAndCallDelegate(_ contentOffset: CGPoint, animated: Bool = false) {
        if animated {
            self.setContentOffset(contentOffset, animated: animated)
        } else {
            self.contentOffset = contentOffset
        }
        self.delegate?.scrollViewDidScroll?(self)
    }

    var mw_visibleRectWithContentInsets: CGRect {
        let visibleRectOrigin = self.contentOffset
        let verticalInset = self.mw_contentInsetWithAdjustments.bottom
        let visibleRectHeight = self.frame.height - verticalInset
        let horizontalInset = self.mw_contentInsetWithAdjustments.left + self.mw_contentInsetWithAdjustments.right
        let visibleRectWidth = self.frame.width - horizontalInset
        let visibleRectSize = CGSize(width: visibleRectWidth, height: visibleRectHeight)
        let visibleRect = CGRect(origin: visibleRectOrigin, size: visibleRectSize)
        return visibleRect
    }

    var mw_contentInsetWithAdjustments: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.adjustedContentInset
        } else {
            return self.contentInset
        }
    }

    var mw_isContentHeightBiggerThenCollectionView: Bool {
        let contentInset = self.mw_contentInsetWithAdjustments
        return self.contentSize.height + contentInset.top + contentInset.bottom > self.frame.height
    }

    var mw_visibleContentRect: CGRect {
        let origin = self.contentOffset
        let width = self.frame.size.width
        let height = self.contentSize.height
        let size = CGSize(width: width, height: height)
        let contentRect = CGRect(origin: origin, size: size)
        let visibleRect = self.mw_visibleRectWithContentInsets
        return contentRect.intersection(visibleRect)
    }
}

extension ChatMessagesViewModelProtocol {
    var lastMessageIndexPath: IndexPath? {
        guard self.messagesDays.count > 0 else { return nil }
        for messageDayIndex in stride(from:(self.messagesDays.count - 1), to:-1, by:-1) {
            let itemsInMessagesDay = self.messagesDays[messageDayIndex].messages.count
            if itemsInMessagesDay > 0 {
                return IndexPath(item: itemsInMessagesDay - 1, section: messageDayIndex)
            }
        }
        return nil
    }

    var messagesCount: Int {
        return self.messagesDays.reduce(0) { (count: Int, day: MessagesDay) -> Int in
            return count + day.messages.count
        }
    }
}

protocol ChatCollectionViewContentSizeObserver: class {
    func chatCollectionView(_ chatCollectionView: ChatCollectionView, contentSizeDidChange newContentSize: CGSize)
}

class ChatCollectionView: UICollectionView {
    weak var contentSizeObserver: ChatCollectionViewContentSizeObserver?

    override var contentSize: CGSize {
        didSet { self.contentSizeObserver?.chatCollectionView(self, contentSizeDidChange: self.contentSize) }
    }
}

struct MessagesUpdateModel {
    var indexPathsToReload = [IndexPath]()
    var indexPathsToInsert = [IndexPath]()
    var indexPathsToDelete = [IndexPath]()
    var indexPathsToMove = [(IndexPath, IndexPath)]()

    var sectionsToInsert = [Int]()
    var sectionsToDelete = [Int]()

    var messages: ChatMessagesViewModelProtocol

    var visibleMessages: [AbstractMessageViewModel]?

    init(messages: ChatMessagesViewModelProtocol) {
        self.messages = messages
    }

    var allUpdatedIndexPaths: [IndexPath] {
        return self.indexPathsToReload +
               self.indexPathsToInsert +
               self.indexPathsToDelete +
               self.indexPathsToMove.flatMap({ [$0.0, $0.1] })
    }

    var isEmpty: Bool {
        return self.indexPathsToReload.isEmpty &&
               self.indexPathsToInsert.isEmpty &&
               self.indexPathsToDelete.isEmpty &&
               self.indexPathsToMove.isEmpty &&
               self.sectionsToInsert.isEmpty &&
               self.sectionsToDelete.isEmpty
    }
}

struct MessagesUpdateQueueItem {
    let messagesChanges: [ChatMessagesViewModelChange]
    let newMessages: ChatMessagesViewModelProtocol
    let visibleMessages: [AbstractMessageViewModel]?
    let isMessagesSet: Bool

    init(messagesChanges: [ChatMessagesViewModelChange],
         newMessages: ChatMessagesViewModelProtocol,
         visibleMessages: [AbstractMessageViewModel]?,
         isMessagesSet: Bool = false) {
        self.messagesChanges = messagesChanges
        self.newMessages = newMessages
        self.visibleMessages = visibleMessages
        self.isMessagesSet = isMessagesSet
    }
}

class ChatViewController: UIViewController,
                          UICollectionViewDelegate,
                          UICollectionViewDataSource,
                          ChatViewProtocol,
                          SBCoordinatorDelegate,
                          CameraManagerDelegate,
                          VideoManagerDelegate,
                          ShowMapViewControllerDelegate,
                          ImagePresenterDelegate,
                          MovieViewControllerDelegate,
                          ChatCollectionViewContentSizeObserver {

    var presenter: ChatPresenterProtocol?
    var fmlActionsHandlerView: FMLActionsHandlerViewProtocol

    var chat: ChatInfoViewModelProtocol!
    var messages: ChatMessagesViewModelProtocol!

    var chatLayout: ChatCollectionViewLayout = {
        let layout = ChatCollectionViewLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        return layout
    }()

    let collectionView: ChatCollectionView

    var topVisibleIndexPath = IndexPath(item: 0, section: 0) {
        didSet {
            self.chatLayout.topVisibleIndexPath = self.topVisibleIndexPath
        }
    }
    var itemsLoadLimit = 40

    let messageViewBuilder: MessageViewBuilder
    let messagesLayoutCache: MessagesLayoutCache
    let headersLayoutCache: HeaderLayoutCache
    var messageCellBuilder: MessageCellBuilder!
    var headerBuilder: ChatHeaderBuilder!

    var updateQueue = [MessagesUpdateQueueItem]()

    var sendBarHeight: NSLayoutConstraint?
    var sendBarBottom: NSLayoutConstraint?

    var sendBar: SBCoordinator?

    var textMessageToEdit: TextMessageViewModel?

    var documentInteractionController: UIDocumentInteractionController?

    var oldVisibleMessages = [AbstractMessageViewModel]()

    let titleView: ChatTitleView = {
        let titleView = ChatTitleView.mw_loadFromSenderFrameworkNibNamed("ChatTitleView")
        titleView.backgroundColor = .clear
        return titleView
    }()

    let scrollToBottomButton: ChatScrollToBottomView = {
        let scrollToBottomButton = ChatScrollToBottomView.mw_loadFromSenderFrameworkNibNamed("ChatScrollToBottomView")
        return scrollToBottomButton
    }()

    let refreshControl = UIRefreshControl()

    let typingIndicator = ChatTypingIndicator()
    let sendBarBackground = UIView()

    var isSendBarDisabled: Bool = false

    init() {
        self.messagesLayoutCache = MessagesLayoutCache()
        self.messageViewBuilder = MessageViewBuilder(cache: self.messagesLayoutCache)
        self.collectionView = ChatCollectionView(frame: .zero, collectionViewLayout: self.chatLayout)
        if #available(iOS 10.0, *) { self.collectionView.isPrefetchingEnabled = false }
        let fmlActionsHandlerView = FMLActionsHandlerView()
        self.fmlActionsHandlerView = fmlActionsHandlerView
        self.headersLayoutCache = HeaderLayoutCache()
        super.init(nibName: nil, bundle: nil)
        self.chatLayout.delegate = self
        self.configureCollectionView()
        self.messageViewBuilder.delegate = self
        self.titleView.delegate = self
        self.scrollToBottomButton.delegate = self
        fmlActionsHandlerView.viewController = self
    }

    public required init?(coder aDecoder: NSCoder) {
        self.messagesLayoutCache = MessagesLayoutCache()
        self.messageViewBuilder = MessageViewBuilder(cache: self.messagesLayoutCache)
        self.collectionView = ChatCollectionView(frame: .zero, collectionViewLayout: self.chatLayout)
        if #available(iOS 10.0, *) { self.collectionView.isPrefetchingEnabled = false }
        let fmlActionsHandlerView = FMLActionsHandlerView()
        self.fmlActionsHandlerView = fmlActionsHandlerView
        self.headersLayoutCache = HeaderLayoutCache()
        super.init(coder: aDecoder)
        self.chatLayout.delegate = self
        self.configureCollectionView()
        self.messageViewBuilder.delegate = self
        self.titleView.delegate = self
        self.scrollToBottomButton.delegate = self
        fmlActionsHandlerView.viewController = self
    }

    func configureCollectionView() {
        self.collectionView.backgroundColor = .white
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.keyboardDismissMode = .interactive
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.alwaysBounceVertical = true
    }

    var sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 2, left: 1, bottom: 0, right: 1)

    var messageWithStatus: AbstractMessageViewModel?

    var typingToScrollToBottomButtonSpace: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.customizeNavigationBar()

        self.view.addSubview(self.collectionView)
        self.view.mw_pinSubview(self.collectionView)
        self.view.layoutIfNeeded()

        let cellWidth = self.chatLayout.contentWidth - (self.sectionInsets.left + self.sectionInsets.right)
        self.messageCellBuilder = MessageCellBuilder(sizingCellWidth: cellWidth)
        self.messageCellBuilder.cellActionsHandler = self
        self.headerBuilder = ChatHeaderBuilder(headerWidth: cellWidth, cache: self.headersLayoutCache)

        self.registerReusableViews()

        self.view.backgroundColor = .white

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.mw_keyboardWillChangeFrame),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.mw_keyboardWillChangeFrame),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        self.navigationItem.titleView = self.titleView

        self.addSendBarBackground()
        self.addScrollToBottomButton()
        self.addTypingIndicator()
        self.addRefreshControl()

        self.presenter?.viewWasLoaded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        //Workaround for quick swipe-to-back to other controller and back
        DispatchQueue.main.async { self.navigationController?.setNavigationBarHidden(false, animated: animated) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter?.viewDidAppear()
        self.sendBar?.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.presenter?.saveSendBarText(self.sendBar?.text, forChat: self.chat)
        self.presenter?.viewDidDisappear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func customizeNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        SenderCore.shared().stylePalette.customize(navigationBar)
        SenderCore.shared().stylePalette.customize(navigationItem)
    }

    func registerReusableViews() {
        self.messageCellBuilder.registerCellsIn(collectionView: self.collectionView)
        self.headerBuilder.registerHeadersIn(collectionView: self.collectionView)
    }

    func addSendBarBackground() {
        self.sendBarBackground.translatesAutoresizingMaskIntoConstraints = false
        self.sendBarBackground.backgroundColor = .white
        self.view.addSubview(self.sendBarBackground)

        let backgroundLayoutAttributes: [NSLayoutAttribute] = [.leading, .trailing, .bottom]
        for layoutAttribute in backgroundLayoutAttributes {
            let constraint = NSLayoutConstraint(item: self.view,
                                                attribute: layoutAttribute,
                                                relatedBy: .equal,
                                                toItem: self.sendBarBackground,
                                                attribute: layoutAttribute,
                                                multiplier: 1.0,
                                                constant: 0.0)
            self.view.addConstraint(constraint)
        }

        let height = NSLayoutConstraint(item: self.sendBarBackground,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .notAnAttribute,
                                        multiplier: 1.0,
                                        constant: 0.0)
        self.view.addConstraint(height)
        self.sendBarHeight = height
    }

    func addSendBarWith(sendBarModel: BarModel?) {
        if let sendBarModel = sendBarModel {
            let sendBar = SBCoordinator(barModel: sendBarModel)
            sendBar.delegate = self
            self.addChildViewController(sendBar)
            sendBarBackground.addSubview(sendBar.view)

            self.sendBarHeight?.constant = sendBar.expectedViewHeight
            let sendBarLayoutAttributes: [NSLayoutAttribute] = [.leading, .trailing, .bottom, .top]
            for layoutAttribute in sendBarLayoutAttributes {
                let constraint = NSLayoutConstraint(item: sendBarBackground,
                                                    attribute: layoutAttribute,
                                                    relatedBy: .equal,
                                                    toItem: sendBar.view,
                                                    attribute: layoutAttribute,
                                                    multiplier: 1.0,
                                                    constant: 0.0)
                if layoutAttribute == .bottom { self.sendBarBottom = constraint }
                sendBarBackground.addConstraint(constraint)
            }

            self.sendBar = sendBar
        } else {
            if let currentSendBar = self.sendBar {
                currentSendBar.removeFromParentViewController()
                currentSendBar.view.removeFromSuperview()
            }
            self.sendBar = nil
        }

        self.setCollectionViewInsetsWith(sendBar: self.sendBar)
    }

    func addScrollToBottomButton() {
        self.scrollToBottomButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scrollToBottomButton)
        let bottom = NSLayoutConstraint(item: self.scrollToBottomButton,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: self.sendBarBackground,
                                          attribute: .top,
                                          multiplier: 1.0,
                                          constant: -10.0)

        let trailing = NSLayoutConstraint(item: self.scrollToBottomButton.button,
                                        attribute: .trailing,
                                        relatedBy: .equal,
                                        toItem: self.view,
                                        attribute: .trailing,
                                        multiplier: 1.0,
                                        constant: -18.0)

        self.view.addConstraint(trailing)
        self.view.addConstraint(bottom)
    }

    func addTypingIndicator() {
        self.typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.typingIndicator)
        self.typingIndicator.isHidden = self.chat?.typingMessage == nil
        let bottom = NSLayoutConstraint(item: self.typingIndicator,
                                          attribute: .bottom,
                                          relatedBy: .equal,
                                          toItem: self.sendBarBackground,
                                          attribute: .top,
                                          multiplier: 1.0,
                                          constant: -10.0)

        let leading = NSLayoutConstraint(item: self.typingIndicator,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .leading,
                                         multiplier: 1.0,
                                         constant: 18.0)

        let trailing = NSLayoutConstraint(item: self.typingIndicator,
                                          attribute: .trailing,
                                          relatedBy: .lessThanOrEqual,
                                          toItem: self.view,
                                          attribute: .trailing,
                                          multiplier: 1.0,
                                          constant: -18.0)
        trailing.priority = UILayoutPriority(900.0)

        let trailingToScrollToBottomButton = NSLayoutConstraint(item: self.typingIndicator,
                                                                attribute: .trailing,
                                                                relatedBy: .lessThanOrEqual,
                                                                toItem: self.scrollToBottomButton,
                                                                attribute: .leading,
                                                                multiplier: 1.0,
                                                                constant: -18.0)

        self.typingToScrollToBottomButtonSpace = trailingToScrollToBottomButton

        self.view.addConstraint(leading)
        self.view.addConstraint(bottom)
        self.view.addConstraint(trailing)
        self.view.addConstraint(trailingToScrollToBottomButton)
    }

    func addRefreshControl() {
        refreshControl.addTarget(self, action: #selector(self.loadTopHistory), for: .valueChanged)
        self.collectionView.addSubview(refreshControl)
    }

    func showErrorWithText(_ errorText: String) {
        let alert = UIAlertController(title: SenderFrameworkLocalizedString("error_ios"),
                                      message: errorText,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: self, animated: true)
    }

    func showInfoWithText(_ infoText: String) {
        let alert = UIAlertController(title: nil,
                                      message: infoText,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: self, animated: true)
    }

    @objc func callByPhone() {
        self.presenter?.callContact()
    }

    @objc func close() {
        self.presenter?.closeChat()
    }

    func fixScrollToBottomButton() {
        guard self.chat.unreadCount == 0 || self.collectionView.mw_isLastItemVisibleWithContentInsets() else {
            self.typingToScrollToBottomButtonSpace?.isActive = true
            self.scrollToBottomButton.isHidden = false
            return
        }

        var lastVisiblePointY = self.collectionView.contentOffset.y + self.collectionView.frame.height
        let contentInset = self.collectionView.mw_contentInsetWithAdjustments
        lastVisiblePointY -= (contentInset.bottom + contentInset.top)
        let contentHeight = self.collectionView.contentSize.height
        let maxBottomOffset = self.collectionView.frame.height / 2
        let hideButton = lastVisiblePointY >= contentHeight || contentHeight - lastVisiblePointY <= maxBottomOffset
        self.typingToScrollToBottomButtonSpace?.isActive = !hideButton
        self.scrollToBottomButton.isHidden = hideButton
    }

    @objc func loadTopHistory() {
        self.presenter?.loadTopHistory()
    }

    func finishLoadingTopHistory() {
        self.refreshControl.endRefreshing()
    }

    func handleSendBarDisabledValue(sendBarDisabled: Bool) {
        guard self.isSendBarDisabled != sendBarDisabled else { return }
        self.isSendBarDisabled = sendBarDisabled
        self.addSendBarWith(sendBarModel: self.isSendBarDisabled ? nil : self.chat.sendBar)
    }

    func handleExternalSendBarActions(_ actions: [[String: Any]]) {
        self.sendBar?.handleActions(actions)
    }

    func setUnsentText(_ unsentText: String?) {
        guard unsentText != nil, (unsentText?.lenght())! > 0 else {
            return
        }
        self.sendBar?.setNewMessageText(unsentText)
    }

    // MARK: - Messages Editing

    func editMessage(_ message: AbstractMessageViewModel) {
        if let textMessage = message as? TextMessageViewModel {
            self.textMessageToEdit = textMessage
            self.sendBar?.editMessage(withText: textMessage.text)
        }
    }

    func deleteMessage(_ message: AbstractMessageViewModel) {
        if let textMessage = message as? TextMessageViewModel {
            self.presenter?.deleteTextMessage(textMessage)
        }
    }

    // MARK: - Showing Media Messages

    func openContentOf(message: AbstractMessageViewModel) {
        if let imageMessage = message as? ImageMessageViewModel {
            self.presenter?.showImageFrom(message: imageMessage)
        } else if let videoMessage = message as? VideoMessageViewModel {
            self.presenter?.showVideoFrom(message: videoMessage)
        } else if let locationMessage = message as? LocationMessageViewModel {
            self.presenter?.showLocationFrom(message: locationMessage)
        } else if let fileMessage = message as? FileMessageViewModel {
            self.presenter?.openFileFrom(message: fileMessage)
        }
    }

    var imagePresenter: ImagePresenter?

    func showImage(_ image: UIImage) {
        let imagePresenter = ImagePresenter()
        imagePresenter.delegate = self
        let startFrame = CGRect(origin: self.view.center, size: .zero)
        let endFrame = self.view.bounds
        imagePresenter.presentWindow(with: image, withTransformFromFrame: startFrame, toFrame: endFrame)
        self.imagePresenter = imagePresenter
    }

    func imagePresenter(_ presenter: ImagePresenter!, didDismissed unused: Bool) {
        if presenter == self.imagePresenter {
            self.imagePresenter = nil
        }
    }

    func showVideoWith(url: URL) {
        let movieViewController = MovieViewController(url: url)
        movieViewController.delegate = self
        self.present(movieViewController, animated: true)
    }

    func movieViewControllerDidFinish(_ movieViewController: MovieViewController!) {
        movieViewController.dismiss(animated: true)
    }

    func showLocation(_ location: CLLocation) {
        let mapController = ShowMapViewController()
        mapController.markedLocation = location
        mapController.delegate = self
        self.present(mapController, animated: true)
    }

    func openFileWith(url: URL) {
        self.documentInteractionController = UIDocumentInteractionController(url: url)
        self.documentInteractionController?.delegate = self
        self.documentInteractionController?.presentOpenInMenu(from: .zero, in: self.view, animated: true)
    }

    // MARK: - Playing Audio Messages

    var currentAudioPlayback: AudioMessagePlaybackViewModel?

    func playAudioFrom(audioMessage: AudioMessageViewModel) {
        self.presenter?.playAudioFrom(message: audioMessage)
    }

    func pauseAudioFrom(audioMessage: AudioMessageViewModel) {
        self.presenter?.pauseAudioFrom(message: audioMessage)
    }

    func handleAudioMessagePlaybackUpdate(_ playbackUpdate: AudioMessagePlaybackViewModel) {
        self.currentAudioPlayback = playbackUpdate
        let playingMessage = playbackUpdate.audioMessage
        guard let indexPath = self.messages.indexPathFor(message: playingMessage),
              let cell = self.collectionView.cellForItem(at: indexPath) as? BaseMessageContainerCell else { return }
        let update = self.messageViewUpdateFrom(audioMessagePlayback: playbackUpdate)
        cell.handleUpdate(update)
    }

    func messageViewUpdateFrom(audioMessagePlayback: AudioMessagePlaybackViewModel) -> MessageViewUpdate {
        let update = MessageViewUpdate(name: MessageViewUpdateAudioMessageInfo)
        update.userInfo = ["progress": audioMessagePlayback.progress, "isPlaying": audioMessagePlayback.isPlaying]
        return update
    }

    // MARK: - Handling Updates

    func chatWasUpdated(chat: ChatInfoViewModelProtocol) {
        if let chat = self.chat { self.presenter?.saveSendBarText(self.sendBar?.text, forChat: chat) }
        self.chat = chat
        self.scrollToBottomButton.counter.text = "\(self.chat.unreadCount)"
        self.scrollToBottomButton.isCounterHidden = self.chat.unreadCount == 0
        self.fixScrollToBottomButton()

        if !self.isSendBarDisabled {
            if let sendBar = self.sendBar {
                sendBar.update(with: chat.sendBar)
            } else {
                self.addSendBarWith(sendBarModel: chat.sendBar)
            }
        }

        self.titleView.title = self.chat.title
        self.titleView.subtitleLabel.text = self.chat.subtitle
        self.titleView.isLockImageHidden = !self.chat.isEncrypted

        if chat.hasPhoneNumber {
            let callButton = UIBarButtonItem(image: UIImage(fromSenderFrameworkNamed:"icPhone"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(ChatViewController.callByPhone))
            self.navigationItem.setRightBarButton(callButton, animated: false)
        } else {
            if #available(iOS 11.0, *) {
                self.navigationItem.setRightBarButton(nil, animated: false)
            } else {
                /*
                 On iOS 9 and 10, back button's width is too big and title view's center is too far from
                 navigation item's center. We set empty right bar button in order to bring some balance.
                 */
                let emptyButton = UIBarButtonItem(image: UIImage(fromSenderFrameworkNamed:"icPhone"),
                                                  style: .plain,
                                                  target: nil,
                                                  action: nil)
                emptyButton.tintColor = .clear
                self.navigationItem.setRightBarButton(emptyButton, animated: false)
            }
        }
    }

    func typingMessageChanged(newChat: ChatInfoViewModelProtocol) {
        self.chat = newChat
        self.typingIndicator.text = newChat.typingMessage?.typingText
        self.typingIndicator.isHidden = newChat.typingMessage == nil
        self.view.layoutIfNeeded()
    }

    func messagesWereSet(newMessagesModel: ChatMessagesViewModelProtocol) {
        let queueItem = MessagesUpdateQueueItem(messagesChanges: [],
                                                newMessages: newMessagesModel,
                                                visibleMessages: nil,
                                                isMessagesSet: true)
        self.addUpdateQueueItem(queueItem)
    }

    func messagesWereChanged(messagesChanges: [ChatMessagesViewModelChange],
                             newMessagesModel: ChatMessagesViewModelProtocol) {
        let visibleMessages = self.collectionView.indexPathsForVisibleItems.flatMap {
            self.messages.messageFor(indexPath: $0)
        }
        messagesChanges.forEach { self.messagesLayoutCache.invalidateCacheFor(keyObject: $0.viewModel) }
        let queueItem = MessagesUpdateQueueItem(messagesChanges: messagesChanges,
                                                newMessages: newMessagesModel,
                                                visibleMessages: visibleMessages)
        self.addUpdateQueueItem(queueItem)
    }

    // MARK: - Updating Collection View

    fileprivate func updateModelWith(messagesChanges: [ChatMessagesViewModelChange],
                                     newMessages: ChatMessagesViewModelProtocol,
                                     messageWithStatus: AbstractMessageViewModel?,
                                     visibleMessages: [AbstractMessageViewModel]?) -> MessagesUpdateModel {
        var updateModel = MessagesUpdateModel(messages: newMessages)
        let messageWithStatusIndexPath: IndexPath?
        if let messageWithStatus = messageWithStatus {
            messageWithStatusIndexPath = newMessages.indexPathFor(message: messageWithStatus)
        } else {
            messageWithStatusIndexPath = nil
        }

        var indexPathsToReload = Set<IndexPath>()

        messagesChanges.forEach { messageChange in
            if messageChange.oldIndexPath == nil {
                if let newIndexPath = messageChange.newIndexPath {
                    if messageChange.isNewMessagesDay { updateModel.sectionsToInsert.append(newIndexPath.messagesDay) }
                    updateModel.indexPathsToInsert.append(newIndexPath)
                }
            } else if messageChange.newIndexPath == nil {
                if let oldIndexPath = messageChange.oldIndexPath {
                    updateModel.indexPathsToDelete.append(oldIndexPath)
                    if messageChange.isDeletedMessagesDay {
                        updateModel.sectionsToDelete.append(oldIndexPath.messagesDay)
                    }
                }
            } else {
                let newIndexPath = messageChange.newIndexPath!
                let oldIndexPath = messageChange.oldIndexPath!

                if oldIndexPath == newIndexPath {
                    indexPathsToReload.insert(newIndexPath)
                } else {
                    updateModel.indexPathsToMove.append((oldIndexPath, newIndexPath))
                }
                if messageChange.isDeletedMessagesDay { updateModel.sectionsToDelete.append(oldIndexPath.messagesDay) }
                if messageChange.isNewMessagesDay { updateModel.sectionsToInsert.append(newIndexPath.messagesDay) }
            }
        }

        updateModel.visibleMessages = visibleMessages
        let messageWithStatusUpdates = self.updatedIndexPathsFor(messageWithStatusIndexPath: messageWithStatusIndexPath,
                                                                 messages: newMessages)
        messageWithStatusUpdates.forEach { indexPathsToReload.insert($0) }
        updateModel.indexPathsToReload = Array(indexPathsToReload)
        updateModel.indexPathsToReload = updateModel.indexPathsToReload.filter {
            !updateModel.indexPathsToInsert.contains($0)
        }

        return updateModel
    }

    fileprivate func updatedIndexPathsFor(messageWithStatusIndexPath: IndexPath?,
                                          messages: ChatMessagesViewModelProtocol) -> [IndexPath] {
        var result = [IndexPath]()
        if let lastMessage = messages.messagesDays.last?.messages.last,
           let lastMessagePath = messages.indexPathFor(message: lastMessage) {
            if let messageWithStatusIndexPath = messageWithStatusIndexPath {
                if lastMessagePath != messageWithStatusIndexPath {
                    result.append(messageWithStatusIndexPath)
                    if !isStatusHiddenFor(message: lastMessage, at: lastMessagePath, inMessages: messages) {
                        result.append(lastMessagePath)
                    }
                }
            } else {
                if !isStatusHiddenFor(message: lastMessage, at: lastMessagePath, inMessages: messages) {
                    result.append(lastMessagePath)
                }
            }
        }
        return result
    }

    fileprivate func updateWith(updateModel: MessagesUpdateModel, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            guard !updateModel.isEmpty else { completion?(); return }
            let shouldScrollToBottom = self.shouldScrollToBottomWith(updateModel: updateModel)
            let oldTopVisibleIndexPath = updateModel.visibleMessages?.flatMap({
                self.messages.indexPathFor(message: $0)
            }).first

            let shouldDisableAnimations: Bool
            if let oldTopVisibleIndexPathUnwrapped = oldTopVisibleIndexPath {
                shouldDisableAnimations = updateModel.allUpdatedIndexPaths.first(where: {
                    $0 <= oldTopVisibleIndexPathUnwrapped
                }) != nil
            } else {
                shouldDisableAnimations = true
            }
            let animationDuration = shouldDisableAnimations ? 0.0 : 0.15

            let updates: () -> Void = {
                var contentOffsetYDelta: CGFloat = 0.0
                if let topIndexPath = oldTopVisibleIndexPath {
                    contentOffsetYDelta -= self.preUpdateContentOffsetYDeltaWith(updateModel: updateModel,
                                                                                 topVisibleIndexPath: topIndexPath)
                }

                self.collectionView.performBatchUpdates({
                    self.messages = updateModel.messages

                    self.collectionView.insertSections(IndexSet(updateModel.sectionsToInsert))
                    self.collectionView.deleteSections(IndexSet(updateModel.sectionsToDelete))
                    self.collectionView.insertItems(at: updateModel.indexPathsToInsert)
                    self.collectionView.deleteItems(at: updateModel.indexPathsToDelete)
                    updateModel.indexPathsToMove.forEach { self.collectionView.moveItem(at: $0.0, to: $0.1) }

                    let newTopVisibleIndexPath: IndexPath! = updateModel.visibleMessages?.flatMap({
                        self.messages.indexPathFor(message: $0)
                    }).first
                    if let topIndexPath = newTopVisibleIndexPath {
                        contentOffsetYDelta += self.postUpdateContentOffsetYDeltaWith(updateModel: updateModel,
                                                                                      topVisibleIndexPath: topIndexPath)
                    }

                    let newContentOffset = CGPoint(x: self.collectionView.contentOffset.x,
                                                   y: self.collectionView.contentOffset.y + contentOffsetYDelta)
                    if newContentOffset != self.collectionView.contentOffset {
                        self.collectionView.mw_setContentOffsetAndCallDelegate(newContentOffset)
                    }
                }) { _ in
                    CATransaction.begin()
                    CATransaction.setCompletionBlock {
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                            self.collectionView.performBatchUpdates({
                                self.collectionView.reloadItems(at: updateModel.indexPathsToReload)
                            }) { _ in
                                /*
                                    Calling scrollViewDidScroll in order to mark messages as visible.
                                    If after updates, there's no need for scrolling,
                                    scrollViewDidScroll won't be called.
                                */
                                self.scrollViewDidScroll(self.collectionView)
                                completion?()
                            }
                        CATransaction.commit()
                    }
                    if shouldScrollToBottom { self.collectionView.mw_scrollToBottomAnimated(true) }
                    CATransaction.commit()
                }
            }
            UIView.animate(withDuration: animationDuration, animations: updates)
        }
    }

    func shouldScrollToBottomWith(updateModel: MessagesUpdateModel) -> Bool {
        guard let lastItemIndexPath = self.collectionView.mw_lastItemIndexPath() else { return true }
        guard self.collectionView.mw_isLastItemVisibleWithContentInsets() else { return false }
        let moveToPaths = updateModel.indexPathsToMove.map { return $0.1 }
        let addedPaths = updateModel.indexPathsToInsert
        let updatePaths = updateModel.indexPathsToReload
        return (addedPaths + moveToPaths + updatePaths).first(where: { $0 >= lastItemIndexPath }) != nil
    }

    var isTopMessagesLoadingDisabled: Bool = false

    fileprivate func setMessages(_ messages: ChatMessagesViewModelProtocol, completion: (() -> Void)?) {
        self.messages = messages
        self.messagesLayoutCache.invalidate()
        let newVisibleIndexPath: IndexPath
        if let lastItemIndexPath = self.messages.lastMessageIndexPath,
           let indexPathWithOffset = self.messages.formMessageIndexPathWith(lastItemIndexPath,
                                                                            offsetBy: -self.itemsLoadLimit) {
            newVisibleIndexPath = indexPathWithOffset
        } else {
            newVisibleIndexPath = IndexPath(messagesDay: 0, message: 0)
        }
        self.topVisibleIndexPath = newVisibleIndexPath
        self.collectionView.contentSizeObserver = self
        self.isTopMessagesLoadingDisabled = true
        self.collectionView.reloadData()

        /*
            We will scroll to bottom in chatCollectionView:contentSizeDidChange: method,
            but we also do in here in case first scroll to bottom wasn't successfully.
        */
        DispatchQueue.main.async {
            self.collectionView.mw_scrollToBottomAnimated(false)
            /*
                Calling scrollViewDidScroll in order to mark messages as visible.
                If after reloading, there's no need for scrolling,
                scrollViewDidScroll won't be called.
            */
            self.scrollViewDidScroll(self.collectionView)
            self.isTopMessagesLoadingDisabled = false
            if let topVisibleIndexPath = self.collectionView.indexPathsForVisibleItems.first,
               self.shouldLoadMoreMessagesFor(indexPath: topVisibleIndexPath) {
                self.loadMoreMessagesOnTop()
            }
            completion?()
        }
    }

    func chatCollectionView(_ chatCollectionView: ChatCollectionView, contentSizeDidChange newContentSize: CGSize) {
        guard chatCollectionView == self.collectionView else { return }
        self.collectionView.mw_scrollToBottomAnimated(false)
        self.collectionView.contentSizeObserver = nil
    }

    fileprivate func addUpdateQueueItem(_ queueItem: MessagesUpdateQueueItem) {
        self.updateQueue.append(queueItem)
        if self.updateQueue.count == 1 { self.runQueue() }
    }

    func runQueue() {
        if let nextUpdate = self.updateQueue.first {
            if nextUpdate.isMessagesSet {
                self.setMessages(nextUpdate.newMessages) {
                    self.updateQueue.remove(at: 0)
                    self.runQueue()
                }
            } else {
                let updateModel = self.updateModelWith(messagesChanges: nextUpdate.messagesChanges,
                                                       newMessages: nextUpdate.newMessages,
                                                       messageWithStatus: self.messageWithStatus,
                                                       visibleMessages: nextUpdate.visibleMessages)
                self.updateWith(updateModel: updateModel) {
                    self.updateQueue.remove(at: 0)
                    self.runQueue()
                }
            }
        }
    }

    private func preUpdateContentOffsetYDeltaWith(updateModel: MessagesUpdateModel,
                                                  topVisibleIndexPath: IndexPath) -> CGFloat {
        var contentHeightChange: CGFloat = 0.0
        let shouldCountSection: ((Int) -> Bool) = { (section: Int) in
            return section < topVisibleIndexPath.section
        }

        let shouldCountIndexPath: ((IndexPath) -> Bool) = { (indexPath: IndexPath) in
            if shouldCountSection(indexPath.section) {
                return true
            } else {
                return (indexPath.section == topVisibleIndexPath.section && indexPath.item < topVisibleIndexPath.item)
            }
        }

        contentHeightChange -= updateModel.sectionsToDelete.reduce(0.0) { result, section -> CGFloat in
            guard shouldCountSection(section) else { return result }
            return result + self.dataSourceSectionAttributesHeightFor(section: section,
                                                                      collectionView: self.collectionView)
        }
        contentHeightChange -= updateModel.indexPathsToDelete.reduce(0.0) { result, path -> CGFloat in
            guard shouldCountIndexPath(path) else { return result }
            return result - self.dataSourceHeightForItemAt(indexPath: path,
                                                           collectionView: self.collectionView)
        }

        return contentHeightChange
    }

    private func postUpdateContentOffsetYDeltaWith(updateModel: MessagesUpdateModel,
                                                   topVisibleIndexPath: IndexPath) -> CGFloat {
        var contentHeightChange: CGFloat = 0.0
        let shouldCountSection: ((Int) -> Bool) = { (section: Int) in
            return section < topVisibleIndexPath.section
        }

        let shouldCountIndexPath: ((IndexPath) -> Bool) = { (indexPath: IndexPath) in
            if shouldCountSection(indexPath.section) {
                return true
            } else {
                return (indexPath.section == topVisibleIndexPath.section && indexPath.item < topVisibleIndexPath.item)
            }
        }

        contentHeightChange += updateModel.sectionsToInsert.reduce(0.0) { result, section -> CGFloat in
            guard shouldCountSection(section) else { return result }
            return result + self.dataSourceSectionAttributesHeightFor(section: section,
                                                                      collectionView: self.collectionView)
        }

        contentHeightChange += updateModel.indexPathsToInsert.reduce(0.0) { result, path -> CGFloat in
            guard shouldCountIndexPath(path) else { return result }
            return result + self.dataSourceHeightForItemAt(indexPath: path,
                                                           collectionView: self.collectionView)
        }

        contentHeightChange += updateModel.indexPathsToMove.reduce(0.0) { result, paths -> CGFloat in
            let oldPath = paths.0
            let newPath = paths.1
            guard shouldCountIndexPath(oldPath) || shouldCountIndexPath(newPath) else { return result }
            let delta: CGFloat
            if oldPath < topVisibleIndexPath, newPath > topVisibleIndexPath {
                delta = -self.dataSourceHeightForItemAt(indexPath: newPath, collectionView: self.collectionView)
            } else if oldPath > topVisibleIndexPath, newPath < topVisibleIndexPath {
                delta = +self.dataSourceHeightForItemAt(indexPath: newPath, collectionView: self.collectionView)
            } else {
                delta = 0.0
            }
            return result + delta
        }

        return contentHeightChange
    }

    private func shouldLoadMoreMessagesFor(indexPath: IndexPath) -> Bool {
        guard self.topVisibleIndexPath != IndexPath(item: 0, section: 0) else { return false }
        let messagesCountBetweenPaths = self.messages.messagesCountBetween(self.topVisibleIndexPath, indexPath)
        return messagesCountBetweenPaths != nil && messagesCountBetweenPaths! <= 20
    }

    private func isVisibleIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section > self.topVisibleIndexPath.section ||
                (indexPath.section == self.topVisibleIndexPath.section &&
                        indexPath.item >= self.topVisibleIndexPath.item)
    }

    fileprivate func isStatusHiddenFor(message: AbstractMessageViewModel,
                                       at indexPath: IndexPath,
                                       inMessages messages: ChatMessagesViewModelProtocol) -> Bool {
        return !(message.author == .owner && indexPath == messages.lastMessageIndexPath)
    }

    // MARK: - SBCoordinator Delegate

    func coordinator(_ coordinator: SBCoordinator!, didSelectItemWithActions actionsArray: [Any]!) {
        if let actions = actionsArray as? [[String: Any]] {
            self.presenter?.handleSendBarActions(actions)
        }
    }

    func coordinator(_ coordinator: SBCoordinator!, didChangeZeroLevelHeight newHeight: CGFloat) {
        self.setCollectionViewInsetsWith(sendBar: coordinator)
    }

    func coordinator(_ coordinator: SBCoordinator!, didChangeInputViewHeight newHeight: CGFloat) {
        self.setCollectionViewInsetsWith(sendBar: coordinator)
    }

    var oldAdjustedContentInsets: UIEdgeInsets = .zero

    func setCollectionViewInsetsWith(sendBar: SBCoordinator?) {
        var newInsets = self.collectionView.contentInset
        let sendBarHeight: CGFloat
        if let sendBar = sendBar {
            sendBarHeight = sendBar.expectedFirstLevelHeight + sendBar.expectedViewHeight
        } else {
            sendBarHeight = 0.0
        }
        newInsets.bottom = sendBarHeight
        self.sendBarHeight?.constant = sendBarHeight
        let sendBarBottom = sendBar?.expectedFirstLevelHeight ?? CGFloat(0.0)
        self.sendBarBottom?.constant = sendBarBottom
        let isKeyboardVisible = MWKeyboardListener.shared().isKeyboardVisible
        let viewHasFirstResponder = self.view.mw_findFirstResponder() != nil
        let isSendBarActive = sendBar?.isActive ?? false
        let isNotSendBarKeyboardOnScreen = !isSendBarActive && viewHasFirstResponder && isKeyboardVisible
        if !isNotSendBarKeyboardOnScreen {
            let oldContentVisibleRect = self.collectionView.mw_visibleContentRect
            self.collectionView.contentInset = newInsets
            self.collectionView.scrollIndicatorInsets = newInsets
            let newContentVisibleRect = self.collectionView.mw_visibleContentRect
            let insetChange = oldContentVisibleRect.height - newContentVisibleRect.height
            if insetChange > 0 {
                var newContentOffset = self.collectionView.contentOffset
                newContentOffset.y += insetChange
                if self.collectionView.contentOffset != newContentOffset {
                    self.collectionView.mw_setContentOffsetAndCallDelegate(newContentOffset)
                }
            }
        }
        self.oldAdjustedContentInsets = self.collectionView.mw_contentInsetWithAdjustments
        self.view.layoutIfNeeded()
    }

    func coordinatorDidActivateFirstLevel(_ coordinator: SBCoordinator!) {
        self.collectionView.mw_scrollToBottomAnimated(true)
    }

    func coordinatorDidExpandTextView(_ coordinator: SBCoordinator!) {
        self.collectionView.mw_scrollToBottomAnimated(true)
    }

    func coordinatorDidType(_ coordinator: SBCoordinator!) {
        self.presenter?.type()
    }

    func coordinator(_ coordinator: SBCoordinator!, didEnterText text: String!) {
        if let textMessageToEdit = self.textMessageToEdit {
            self.presenter?.editTextMessage(textMessageToEdit, withText: text)
            self.textMessageToEdit = nil
        } else {
            self.presenter?.sendMessageWith(text: text)
            if let chat = self.chat { self.presenter?.saveSendBarText(nil, forChat: chat)}
        }
    }

    func coordinator(_ coordinator: SBCoordinator!, didSelectStickerWithID stickerID: String!) {
        self.presenter?.sendStickerWith(stickerID: stickerID)
    }

    func coordinator(_ coordinator: SBCoordinator!, didRecordedAudioWith audioData: Data!) {
        self.presenter?.sendAudioMessageWith(data: audioData)
    }

    func coordinatorDidCancelEditingText(_ coordinator: SBCoordinator!) {
        self.textMessageToEdit = nil
    }

    // MARK: - Media Pickers

    func checkCameraAccess() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            let alert = UIAlertController(title: SenderFrameworkLocalizedString("error_ios"),
                                          message: SenderFrameworkLocalizedString("device_without_camera_ios"),
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel,
                                         handler: nil)
            alert.addAction(okAction)
            alert.mw_safePresentIn(viewController: self, animated: true, completion: nil)
            return false
        }
        return true
    }

    func showMediaPickerFor(mediaType: ChatMediaType) {
        switch mediaType {
        case .photo: if self.checkCameraAccess() { self.showPhotoPicker() }
        case .video: if self.checkCameraAccess() { self.showVideoPicker() }
        case .location: self.showLocationPicker()
        }
    }

    var cameraManager: CameraManager?

    func showPhotoPicker() {
        self.cameraManager = CameraManager(parentController: self, chat: nil)
        self.cameraManager?.delegate = self
        self.cameraManager?.showCamera()
    }

    var videoManager: VideoManager?

    func showVideoPicker() {
        self.videoManager = VideoManager(parentController: self)
        self.videoManager?.delegate = self
        self.videoManager?.showCamera()
    }

    func showLocationPicker() {
        let mapController = ShowMapViewController()
        mapController.delegate = self
        self.present(mapController, animated: true)
    }

    // MARK: - CameraManager Delegate
    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPicking image: UIImage?,
                       withAssetID assetID: String?) {
        self.dismiss(animated: true)
        self.cameraManager = nil
        self.presenter?.sendImageWith(assetID: assetID, image: image)
    }

    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPickingVideoWithAssetID assetID: String!,
                       duration: TimeInterval) {
        self.dismiss(animated: true)
        self.cameraManager = nil
        self.presenter?.sendVideoWith(assetID: assetID, data: nil, duration: duration)
    }

    func cameraManagerDidFinishWithError(_ error: Error!) {
        self.dismiss(animated: true)
        self.cameraManager = nil
    }

    // MARK: - VideoManager Delegate

    func videoManager(_ videoManager: VideoManager!, didFinishPickingVideoWith data: Data!, duration: TimeInterval) {
        self.dismiss(animated: true)
        self.videoManager = nil
        self.presenter?.sendVideoWith(assetID: nil, data: data, duration: duration)
    }

    func videoManager(_ videoManager: VideoManager!, didFinishWithError error: Error!) {
        self.dismiss(animated: true)
        self.videoManager = nil
    }

    // MARK: - ShowMapViewController Delegate

    func showMapViewController(_ controller: ShowMapViewController!,
                               didFinishEntering location: CLLocation!,
                               with image: UIImage!,
                               description: String!) {
        self.dismiss(animated: true)
        guard let location = location else { return }
        self.presenter?.sendLocation(location, withImage: image, description: description)
    }

    // MARK: - UICollectionView DataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.messages?.messagesDays.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return self.messages?.messagesDays[section].messages.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let message = self.messages?.messageFor(indexPath: indexPath) else {
            fatalError("Cannot get message for indexPath: \(indexPath)")
        }
        return self.messageCellBuilder.collectionView(collectionView,
                                                      reusableCellForMessage: message,
                                                      at: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        return self.headerBuilder.collectionView(collectionView,
                                                 reusableViewForSupplementaryElementOfKind: kind,
                                                 at: indexPath)
    }

    // MARK: - UICollectionView Delegate

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard self.isVisibleIndexPath(indexPath),
              let message = self.messages.messageFor(indexPath: indexPath) else { return }
        let isStatusHidden = self.isStatusHiddenFor(message: message, at: indexPath, inMessages: self.messages)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.messageCellBuilder.customizeCell(cell,
                                              at: indexPath,
                                              withMessage: message,
                                              isStatusHidden: isStatusHidden,
                                              chat: self.chat,
                                              messageViewBuilder: self.messageViewBuilder)
        if let currentAudioPlayback = self.currentAudioPlayback, message == currentAudioPlayback.audioMessage {
            let messageUpdate = self.messageViewUpdateFrom(audioMessagePlayback: currentAudioPlayback)
            (cell as? BaseMessageContainerCell)?.handleUpdate(messageUpdate)
        }
        cell.layoutIfNeeded()
        CATransaction.commit()
        if indexPath == self.collectionView.mw_lastItemIndexPath() {
            self.messageWithStatus = isStatusHidden ? nil : message
        }
        if !self.isTopMessagesLoadingDisabled && self.shouldLoadMoreMessagesFor(indexPath: indexPath) {
            self.loadMoreMessagesOnTop()
        }
    }

    func loadMoreMessagesOnTop() {
        /*
            If one of cells contains subview which is first responder,
            invalidating collection view's layout will make cell disappear.
        */
        UIView.animate(withDuration: 0.25) { self.collectionView.mw_findFirstResponder()?.endEditing(false) }
        let oldContentOffset = self.collectionView.contentOffset
        let oldContentHeight = self.collectionView.contentSize.height

        let indexPathWithOffset = self.messages.formMessageIndexPathWith(self.topVisibleIndexPath, offsetBy: -20)
        let newVisibleIndexPath = indexPathWithOffset ?? IndexPath(messagesDay: 0, message: 0)
        self.topVisibleIndexPath = newVisibleIndexPath

        self.collectionView.collectionViewLayout.invalidateLayout()

        let newContentHeight = self.dataSourceContentHeightFor(collectionView: self.collectionView,
                                                               collectionViewDataSource: self)
        let contentHeightChange = newContentHeight - oldContentHeight
        let newContentOffset = CGPoint(x: self.collectionView.contentOffset.x,
                                       y: oldContentOffset.y + contentHeightChange)
        self.collectionView.mw_setContentOffsetAndCallDelegate(newContentOffset)
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String,
                        at indexPath: IndexPath) {
        guard elementKind == UICollectionElementKindSectionHeader,
              let header = view as? NotificationContainerCell else { return }
        let messagesDay = self.messages.messagesDays[indexPath.section]
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.headerBuilder.customizeHeader(header, at: indexPath, withMessagesDay: messagesDay)
        header.layoutIfNeeded()
        CATransaction.commit()
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView == self.collectionView {
            collectionView.scrollToItem(at: self.topVisibleIndexPath,
                                        at: .top,
                                        animated: true)
            return false
        }
        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.fixScrollToBottomButton()

        let visibleRect = self.collectionView.mw_visibleRectWithContentInsets
        let collectionViewLayout = self.collectionView.collectionViewLayout
        guard let visibleAttributes = collectionViewLayout.layoutAttributesForElements(in: visibleRect) else {
            return
        }
        let visibleCellAttributes = visibleAttributes.filter { $0.representedElementCategory == .cell }
        let visibleIndexPaths = visibleCellAttributes.map { $0.indexPath }
        let visibleMessages = visibleIndexPaths.flatMap { self.messages.messageFor(indexPath: $0) }
        visibleMessages.forEach { if !self.oldVisibleMessages.contains($0) { self.presenter?.viewDidShowMessage($0) } }
        self.oldVisibleMessages = visibleMessages
    }
}

// MARK: - ChatCollectionViewLayout Delegate

extension ChatViewController: ChatCollectionViewLayoutDelegate {
    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  heightForHeaderInSection section: Int) -> CGFloat? {
        guard section < self.messages.messagesDays.count else { return nil }
        let messagesDay = self.messages.messagesDays[section]
        return self.headerBuilder.sizeOfHeaderWith(messagesDay: messagesDay, inSection: section).height
    }

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  heightForFooterInSection section: Int) -> CGFloat? {
        return nil
    }

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        guard let message = self.messages?.messageFor(indexPath: indexPath) else { return .zero }
        let isStatusHidden = self.isStatusHiddenFor(message: message, at: indexPath, inMessages: self.messages)
        let size = self.messageCellBuilder.sizeOfCellWith(message: message,
                                                          at: indexPath,
                                                          isStatusHidden: isStatusHidden,
                                                          chat: self.chat,
                                                          messageViewBuilder: self.messageViewBuilder)
        return size
    }

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  prefetchSizeForItemAtIndexPath indexPath: IndexPath) {
        guard let message = self.messages?.messageFor(indexPath: indexPath),
              !(message is FormMessageViewModel) else { return }
        DispatchQueue.global().async {
            self.messageCellBuilder.prefetchSizeOfCellWith(message: message,
                                                           at: indexPath,
                                                           chat: self.chat,
                                                           messageViewBuilder: self.messageViewBuilder)
        }
    }

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  spaceBetweenItemsInSection section: Int) -> CGFloat {
        return 2.0
    }

    func chatCollectionViewLayout(_ chatCollectionViewLayout: ChatCollectionViewLayout,
                                  insetsForSection section: Int) -> UIEdgeInsets {
        return self.sectionInsets
    }
}

extension ChatCollectionViewLayoutDelegate {
    func dataSourceSectionAttributesHeightFor(section: Int, collectionView: UICollectionView) -> CGFloat {
        guard let chatLayout = collectionView.collectionViewLayout as? ChatCollectionViewLayout else { return 0.0 }
        var height: CGFloat = 0.0
        if chatLayout.isSectionHeaderVisible(section) {
            height += self.chatCollectionViewLayout(chatLayout, heightForHeaderInSection: section) ?? 0.0
        }
        if chatLayout.isSectionFooterVisible(section) {
            height += self.chatCollectionViewLayout(chatLayout, heightForFooterInSection: section) ?? 0.0
        }
        if chatLayout.isSectionHeaderVisible(section) {
            let sectionInset = self.chatCollectionViewLayout(chatLayout, insetsForSection: section)
            height += (sectionInset.top + sectionInset.bottom)
        }
        return height
    }

    func dataSourceHeightFor(section: Int,
                             collectionView: UICollectionView,
                             collectionViewDataSource: UICollectionViewDataSource) -> CGFloat {
        guard let chatLayout = collectionView.collectionViewLayout as? ChatCollectionViewLayout else { return 0.0 }

        var height: CGFloat = 0.0
        height += self.dataSourceSectionAttributesHeightFor(section: section, collectionView: collectionView)
        for item in 0..<(collectionViewDataSource.collectionView(collectionView, numberOfItemsInSection: section)) {
            let itemIndexPath = IndexPath(item: item, section: section)
            height += self.dataSourceHeightForItemAt(indexPath: itemIndexPath, collectionView: collectionView)
        }
        if chatLayout.isSectionVisible(section) {
            height -= self.chatCollectionViewLayout(chatLayout, spaceBetweenItemsInSection: section)
        }
        return height
    }

    func dataSourceHeightForItemAt(indexPath: IndexPath,
                                   collectionView: UICollectionView) -> CGFloat {
        guard let chatLayout = collectionView.collectionViewLayout as? ChatCollectionViewLayout,
              chatLayout.isItemVisibleAt(indexPath: indexPath) else { return 0.0 }

        var height: CGFloat = 0.0
        height += self.chatCollectionViewLayout(chatLayout, sizeForItemAtIndexPath: indexPath).height
        height += self.chatCollectionViewLayout(chatLayout, spaceBetweenItemsInSection: indexPath.section)
        return height
    }

    func dataSourceContentHeightFor(collectionView: UICollectionView,
                                    collectionViewDataSource: UICollectionViewDataSource) -> CGFloat {
        guard collectionView.collectionViewLayout is ChatCollectionViewLayout,
              let numberOfSection = collectionViewDataSource.numberOfSections?(in: collectionView),
              numberOfSection > 0 else { return 0.0 }
        var height: CGFloat = 0.0
        for section in 0..<numberOfSection {
            height += self.dataSourceHeightFor(section: section,
                                               collectionView: collectionView,
                                               collectionViewDataSource: collectionViewDataSource)
        }
        return height
    }
}

extension ChatViewController {
    @objc func mw_keyboardWillChangeFrame(notification: Notification) {
        guard !(self.sendBar?.isActive ?? false) else { return }

        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        var bottomInset = collectionView.frame.maxY - keyboardFrame.minY
        if let sendBar = self.sendBar,
           bottomInset < sendBar.expectedViewHeight + sendBar.expectedFirstLevelHeight {
            bottomInset = sendBar.expectedViewHeight + sendBar.expectedFirstLevelHeight
        }
        var newContentInset = self.collectionView.contentInset
        newContentInset.bottom = bottomInset
        let curveRaw = (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let animationCurve = UIViewAnimationOptions(rawValue: UInt(curveRaw << 16))

        var newContentOffset = self.collectionView.contentOffset

        if notification.name != .UIKeyboardWillHide,
           let firstResponder = self.collectionView.mw_findFirstResponder(),
           let firstResponderSuperview = firstResponder.superview {
            let firstResponderFrame = self.view.convert(firstResponder.frame, from: firstResponderSuperview)
            let contentOffsetDelta = firstResponderFrame.maxY - keyboardFrame.minY
            if contentOffsetDelta > 0 { newContentOffset.y += contentOffsetDelta }
        }

        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: animationCurve,
                       animations: {
                           if newContentOffset != self.collectionView.contentOffset {
                               self.collectionView.mw_setContentOffsetAndCallDelegate(newContentOffset, animated: true)
                           }
                           self.collectionView.contentInset = newContentInset
                           self.collectionView.scrollIndicatorInsets = newContentInset
                       }, completion: nil)
    }
}

extension ChatViewController: MessageViewBuilderDelegate {
    func messageViewBuilder(_ messageViewBuilder: MessageViewBuilder,
                            fmlEventsHandlerFor formViewModel: FormMessageViewModel) -> PBConsoleViewDelegate {
        return self.fmlActionsHandlerView
    }
}

extension ChatViewController: ChatTitleViewDelegate {
    func chatTitleViewDidPressChatTitle(_ chatTitleView: ChatTitleView) {
        self.presenter?.openChatSettings()
    }
}

extension ChatViewController: ChatScrollToBottomViewDelegate {
    func chatScrollToBottomViewWasPressed(_ chatScrollToBottomView: ChatScrollToBottomView) {
        self.collectionView.mw_scrollToBottomAnimated(true)
    }
}

extension MessageViewAction {
    public static func == (lhs: MessageViewAction, rhs: MessageViewAction) -> Bool {
        return lhs.name == rhs.name
    }
}

extension ChatViewController: BaseMessageContainerCellActionHandler {
    func messageContainerCell(_ messageContainerCell: BaseMessageContainerCell,
                              didSelectAction action: MessageViewAction) {
        guard let indexPath = self.collectionView.indexPath(for: messageContainerCell),
              let message = self.messages.messageFor(indexPath: indexPath) as? AbstractMessageViewModel else { return }
        switch action.name {
        case MessageViewAction.edit.name:
            self.editMessage(message)
        case MessageViewAction.delete.name:
            self.deleteMessage(message)
        case MessageViewAction.openMedia.name:
            self.openContentOf(message: message)
        case MessageViewAction.playAudio.name:
            if let audioMessage = message as? AudioMessageViewModel { self.playAudioFrom(audioMessage: audioMessage) }
        case MessageViewAction.pauseAudio.name:
            if let audioMessage = message as? AudioMessageViewModel { self.pauseAudioFrom(audioMessage: audioMessage) }
        case MessageViewAction.openChat.name:
            self.presenter?.openChatFrom(message: message)
        default: break
        }
    }

    func messageContainerCell(_ messageContainerCell: BaseMessageContainerCell,
                              canPerformAction action: MessageViewAction) -> Bool {
        guard let indexPath = self.collectionView.indexPath(for: messageContainerCell),
              let message = self.messages.messageFor(indexPath: indexPath) as? TextMessageViewModel else { return true }
        let canPerformAction: Bool
        if action == .edit || action == .delete {
            canPerformAction = message.isEditable && !message.isDeleted
        } else {
            canPerformAction = true
        }
        return canPerformAction
    }
}

extension ChatViewController: UIDocumentInteractionControllerDelegate {
}

extension ChatViewController: ModalInNavigationWireframeEventsHandler {
    func prepareForPresentationWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
        let closeImage = UIImage(fromSenderFrameworkNamed: "close")?.withRenderingMode(.alwaysTemplate)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage,
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(close))
    }

    func prepareForDismissalWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
    }
}
