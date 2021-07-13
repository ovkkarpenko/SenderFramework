//
// Created by Roman Serga on 3/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public protocol P2PChatSettingsViewProtocol: ChatSettingsViewProtocol {
    var presenter: P2PChatSettingsPresenterProtocol? { get set }
}

public protocol P2PChatSettingsPresenterProtocol: ChatSettingsPresenterProtocol {
    weak var view: P2PChatSettingsViewProtocol? { get set }
    var router: P2PChatSettingsRouterProtocol? { get set }
    var interactor: P2PChatSettingsInteractorProtocol { get set }

    func writeToChat()
    func editChatWith(name: String)
    func changeIsDeletedStateTo(_ newIsDeleted: Bool)
    func complaintWith(text: String)

    func topUpMobile()
    func transfer()
}

public protocol P2PChatSettingsRouterProtocol: ChatSettingsRouterProtocol {
    weak var presenter: P2PChatSettingsPresenterProtocol? { get set }
}

public protocol P2PChatSettingsInteractorProtocol: ChatSettingsInteractorProtocol {
    weak var presenter: P2PChatSettingsPresenterProtocol? { get set }

    func editChatWith(name: String)
    func changeIsDeletedStateTo(_ newIsDeleted: Bool)
    func complaintWith(text: String)
}

public protocol P2PChatSettingsDataManagerProtocol: ChatSettingsDataManagerProtocol {
    func edit(p2pChat: Dialog,
              withName name: String?,
              phone: String?,
              completionHandler: ((Dialog?, Error?) -> Void)?)
    func save(p2pChat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
    func delete(chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
    func complainAbout(user: Contact, withText text: String, completion: ((Bool) -> Void)?)
}
