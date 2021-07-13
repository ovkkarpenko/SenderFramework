//
// Created by Roman Serga on 12/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class MessageCellBuilder {

    let sizingCellWidth: CGFloat

    let ownerSizingCell: OwnerMessageContainerCell
    let systemSizingCell: NotificationContainerCell
    let interlocutorSizingCell: InterlocutorMessageContainerCell
    let formSizingCell: BaseMessageContainerCell

    weak var cellActionsHandler: BaseMessageContainerCellActionHandler?

    let defaultImagesCache = MW_PSPDFThreadSafeMutableDictionary()

    init(sizingCellWidth: CGFloat) {
        self.sizingCellWidth = sizingCellWidth

        let cellFrame = CGRect(x: 0.0, y: 0.0, width: self.sizingCellWidth, height: 0.0)
        self.ownerSizingCell = OwnerMessageContainerCell(frame: cellFrame)
        self.ownerSizingCell.layoutIfNeeded()

        self.systemSizingCell = NotificationContainerCell(frame: cellFrame)
        self.systemSizingCell.layoutIfNeeded()

        self.interlocutorSizingCell = InterlocutorMessageContainerCell(frame: cellFrame)
        self.interlocutorSizingCell.layoutIfNeeded()

        self.formSizingCell = BaseMessageContainerCell(frame: cellFrame)
        self.formSizingCell.layoutIfNeeded()
    }

    func registerCellsIn(collectionView: UICollectionView) {
        collectionView.register(OwnerMessageContainerCell.self,
                                forCellWithReuseIdentifier: "ownerMessageCell")
        collectionView.register(InterlocutorMessageContainerCell.self,
                                forCellWithReuseIdentifier: "interlocutorMessageCell")
        collectionView.register(NotificationContainerCell.self,
                                forCellWithReuseIdentifier: "systemMessageCell")
        collectionView.register(BaseMessageContainerCell.self,
                                forCellWithReuseIdentifier: "formMessageCell")
    }

    func collectionView(_ collectionView: UICollectionView,
                        reusableCellForMessage message: AbstractMessageViewModel,
                        at indexPath: IndexPath) -> UICollectionViewCell {
        let identifier: String
        switch message.author {
        case .owner: identifier = "ownerMessageCell"
        case .interlocutor: identifier = "interlocutorMessageCell"
        case .system: identifier = message is FormMessageViewModel ? "formMessageCell" : "systemMessageCell"
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        return cell
    }

    func customizeCell(_ cell: UICollectionViewCell,
                       at indexPath: IndexPath,
                       withMessage message: AbstractMessageViewModel,
                       isStatusHidden: Bool,
                       chat: ChatInfoViewModelProtocol,
                       messageViewBuilder: MessageViewBuilder) {
        guard let cell = cell as? BaseMessageContainerCell else { return }
        UIView.performWithoutAnimation { cell.layoutIfNeeded() }
        self.setUpCellLayout(cell: cell,
                             withMessage: message,
                             at: indexPath,
                             isStatusHidden: isStatusHidden,
                             chat: chat)

        if let interlocutorCell = cell as? InterlocutorMessageContainerCell {
            if let concreteMessageModel = message as? MessageViewModel {
                
                var name = concreteMessageModel.fromName
                
                if concreteMessageModel.message.operatorName != nil, concreteMessageModel.message.operatorName.hasLenght() {
                    name = concreteMessageModel.message.operatorName!
//                    interlocutorCell.profileNameHidden = false
//                    interlocutorCell.layoutSubviews()
                }
                
                interlocutorCell.profileNameLabel.text = name
                interlocutorCell.profilePhotoButton.sd_cancelCurrentImageLoad()
                let placeholderSize = interlocutorCell.profilePhotoButton.frame.size
                let placeholder = self.getDefaultImageFor(message: concreteMessageModel, size: placeholderSize)
                if let fromPhotoURL = concreteMessageModel.fromPhotoURL {
                    
                    var fromPhotoURL_ = fromPhotoURL
                    
                    if concreteMessageModel.message.operatorImageURL != nil, concreteMessageModel.message.operatorImageURL.hasLenght(), let url = URL(string: concreteMessageModel.message.operatorImageURL!) {
                        fromPhotoURL_ = url
                    }
                    
                    interlocutorCell.profilePhotoButton.sd_setImage(with: fromPhotoURL_,
                                                                    for: .normal,
                                                                    placeholderImage: placeholder,
                                                                    options: .retryFailed) { image, _, _, _ in
                        guard let image = image else { return }
                        let imageSide = interlocutorCell.profilePhotoButton.frame.height
                        let roundedImage = image.mw_roundedImageWith(side: imageSide)
                        interlocutorCell.profilePhotoButton.setImage(roundedImage, for: .normal)
                    }
                } else {
                    interlocutorCell.profilePhotoButton.setImage(placeholder, for: .normal)
                }
            }
        } else if let ownerCell = cell as? OwnerMessageContainerCell {
            ownerCell.statusLabel.text = isStatusHidden ? "" : chat.messagesStatusDescription
        }
        let content = message.buildViewWith(viewBuilder: messageViewBuilder, maxWidth: cell.maxContainerViewWidth)
        cell.setContent(content)
        content.actionsHandler = cell
        cell.messageView = content
        cell.actionHandler = self.cellActionsHandler
    }

    func getDefaultImageFor(message: MessageViewModel, size: CGSize) -> UIImage? {
        let key = message.fromID + NSStringFromCGSize(size)
        if let cachedImage = self.defaultImagesCache[key] as? UIImage {
            return cachedImage
        } else {
            let image = message.defaultPhotoWith(size: size, rounded: true)
            self.defaultImagesCache[key] = image
            return image
        }
    }

    func sizeOfCellWith(message: AbstractMessageViewModel,
                        at indexPath: IndexPath,
                        isStatusHidden: Bool,
                        chat: ChatInfoViewModelProtocol,
                        messageViewBuilder: MessageViewBuilder) -> CGSize {
        let sizingCell = sizingCellFor(message: message)
        self.setUpCellLayout(cell: sizingCell,
                             withMessage: message,
                             at: indexPath,
                             isStatusHidden: isStatusHidden,
                             chat: chat)
        let contentSize = message.sizeOfViewWith(viewBuilder: messageViewBuilder,
                                                 maxWidth:sizingCell.maxContainerViewWidth)
        let size = sizingCell.sizeWith(contentSize: contentSize)
        return size
    }

    func prefetchSizeOfCellWith(message: AbstractMessageViewModel,
                                at indexPath: IndexPath,
                                chat: ChatInfoViewModelProtocol,
                                messageViewBuilder: MessageViewBuilder) {
        let sizingCell = sizingCellFor(message: message)
        _ = message.sizeOfViewWith(viewBuilder: messageViewBuilder, maxWidth:sizingCell.maxContainerViewWidth)
    }

    fileprivate func setUpCellLayout(cell: BaseMessageContainerCell,
                                     withMessage message: AbstractMessageViewModel,
                                     at indexPath: IndexPath,
                                     isStatusHidden: Bool,
                                     chat: ChatInfoViewModelProtocol) {
        if let interlocutorCell = cell as? InterlocutorMessageContainerCell {
            interlocutorCell.profileNameHidden = self.isProfileNameHiddenFor(message: message,
                                                                             at: indexPath,
                                                                             inChat: chat)
            let profilePhotoHidden: Bool
            if let concreteMessageModel = message as? MessageViewModel {
                profilePhotoHidden = self.isProfilePhotoHiddenFor(message: concreteMessageModel,
                                                                  at: indexPath,
                                                                  inChat: chat)
            } else {
                profilePhotoHidden = true
            }
            interlocutorCell.profilePhotoHidden = profilePhotoHidden
        } else if let ownerCell = cell as? OwnerMessageContainerCell {
            ownerCell.statusHidden = isStatusHidden
        }
    }

    fileprivate func sizingCellFor(message: AbstractMessageViewModel) -> BaseMessageContainerCell {
        let sizingCell: BaseMessageContainerCell

        switch message.author {
        case .owner: sizingCell = ownerSizingCell
        case .interlocutor: sizingCell = interlocutorSizingCell
        case .system: sizingCell = message is FormMessageViewModel ? formSizingCell : systemSizingCell
        }
        return sizingCell
    }

    fileprivate func isProfilePhotoHiddenFor(message: MessageViewModel,
                                             at indexPath: IndexPath,
                                             inChat chat: ChatInfoViewModelProtocol) -> Bool {
        return message.isGluedWithPreviousMessage
    }

    fileprivate func isProfileNameHiddenFor(message: AbstractMessageViewModel,
                                            at indexPath: IndexPath,
                                            inChat chat: ChatInfoViewModelProtocol) -> Bool {
        guard !chat.isP2P,
              let concreteMessageModel = message as? MessageViewModel else { return true }
        return concreteMessageModel.isGluedWithPreviousMessage
    }
}
