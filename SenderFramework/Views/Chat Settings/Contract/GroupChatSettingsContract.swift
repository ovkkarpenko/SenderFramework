//
// Created by Roman Serga on 3/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public protocol GroupChatSettingsViewProtocol: ChatSettingsViewProtocol {
    var presenter: GroupChatSettingsPresenterProtocol? { get set }
}

public protocol GroupChatSettingsPresenterProtocol: ChatSettingsPresenterProtocol {
    weak var view: GroupChatSettingsViewProtocol? { get set }
    var router: GroupChatSettingsRouterProtocol? { get set }
    var interactor: GroupChatSettingsInteractorProtocol { get set }

    func goToChatWith(member: ChatSettingsMemberViewModel)
    func deleteMember(_ member: ChatSettingsMemberViewModel)
    func editWith(name: String?, description: String?, image: UIImage?)
    func leaveChat()
}

public protocol GroupChatSettingsRouterProtocol: ChatSettingsRouterProtocol {
    weak var presenter: GroupChatSettingsPresenterProtocol? { get set }
}

public protocol GroupChatSettingsInteractorProtocol: ChatSettingsInteractorProtocol {
    weak var presenter: GroupChatSettingsPresenterProtocol? { get set }

    func deleteMember(_ member: ChatMember)
    func editWith(name: String?, description: String?, image: UIImage?)
    func leaveChat()
}

public protocol GroupChatSettingsDataManagerProtocol: ChatSettingsDataManagerProtocol {
    func edit(chat: Dialog,
              withName name: String?,
              description: String?,
              imageData: Data?,
              completionHandler: ((Dialog?, Error?) -> Void)?)

    func deleteMembers(_ members: [ChatMember],
                       ofChat chat: Dialog,
                       completionHandler: ((Dialog?, Error?) -> Void)?)

    func leave(chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
}
