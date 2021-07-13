//
// Created by Roman Serga on 3/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

public protocol CompanyChatSettingsViewProtocol: ChatSettingsViewProtocol {
    var presenter: CompanyChatSettingsPresenterProtocol? { get set }
    var fmlActionsHandlerView: FMLActionsHandlerViewProtocol { get set }

    func updateWith(companyCard: CompanyCard)
    func showShareScreenWith(items: [Any])
    func showInfoWithText(_ infoText: String)
}

public protocol CompanyChatSettingsPresenterProtocol: ChatSettingsPresenterProtocol {
    weak var view: CompanyChatSettingsViewProtocol? { get set }
    var router: CompanyChatSettingsRouterProtocol? { get set }
    var interactor: CompanyChatSettingsInteractorProtocol { get set }
    var fmlActionsHandlerPresenter: FMLActionsHandlerPresenterProtocol { get set }

    func loadCompanyCard()
    func companyCardWasUpdated(_ companyCard: CompanyCard)

    func complaintWith(text: String)
    func changeIsDeletedStateTo(_ newIsDeleted: Bool)
}

public protocol CompanyChatSettingsRouterProtocol: ChatSettingsRouterProtocol {
    weak var presenter: CompanyChatSettingsPresenterProtocol? { get set }
    var fmlActionsHandlerRouter: FMLActionsHandlerRouterProtocol { get set }
}

public protocol CompanyChatSettingsInteractorProtocol: ChatSettingsInteractorProtocol, MessagesChangesHandler {
    weak var presenter: CompanyChatSettingsPresenterProtocol? { get set }
    var fmlActionsHandlerInteractor: FMLActionsHandlerInteractorProtocol { get set }

    func loadCompanyCard()
    func changeIsDeletedStateTo(_ newIsDeleted: Bool)
    func complaintWith(text: String)
}

public protocol CompanyChatSettingsDataManagerProtocol: ChatSettingsDataManagerProtocol {
    func loadCompanyCardFor(chat: Dialog, completion: ((Bool, Error?) -> Void)?)
    func save(p2pChat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
    func delete(chat: Dialog, completionHandler: ((Dialog?, Error?) -> Void)?)
    func complainAbout(user: Contact, withText text: String, completion: ((Bool) -> Void)?)

    func startMessagesChangesObservingWith(messagesChangesHandler: MessagesChangesHandler)
    func stopMessagesChangesObserving()

    func chatWith(chatID: String) -> Dialog
}
