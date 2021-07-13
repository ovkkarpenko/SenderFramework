//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GroupChatSettingsInteractor: ChatSettingsInteractor, GroupChatSettingsInteractorProtocol {
    weak var presenter: GroupChatSettingsPresenterProtocol? {
        didSet { self._presenter = self.presenter }
    }

    var dataManager: GroupChatSettingsDataManagerProtocol

    init(dataManager: GroupChatSettingsDataManagerProtocol) {
        self.dataManager = dataManager
        super.init(dataManager: dataManager)
    }

    func deleteMember(_ member: ChatMember) {
        self.dataManager.deleteMembers([member],
                                       ofChat: self.chat,
                                       completionHandler: nil)
    }

    func editWith(name: String?, description: String?, image: UIImage?) {
        let imageData: Data?
        if let image = image {
            if image.size == .zero {
                imageData = Data()
            } else {
                let mediaEditor = MediaEditor()
                let compressionResult = mediaEditor.compressedImage(image, withScaleRatio: 2.0, compressionQuality: 0.6)
                imageData = compressionResult?.1 ?? Data()
            }
        } else {
            imageData = nil
        }
        self.dataManager.edit(chat: self.chat,
                              withName: name,
                              description: description,
                              imageData: imageData,
                              completionHandler: nil)
    }

    func leaveChat() {
        self.dataManager.leave(chat: self.chat, completionHandler: nil)
    }
}
