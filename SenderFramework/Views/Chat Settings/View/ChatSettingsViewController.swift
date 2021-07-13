//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

enum ChatSettingsViewOptionType {
    case boolean
    case select
}

struct ChatSettingsViewOption {
    let type: ChatSettingsViewOptionType
    let identifier: String
    var title: String
    var imageText: String?

    init(type: ChatSettingsViewOptionType,
         identifier: String,
         title: String,
         imageText: String? = nil) {
        self.type = type
        self.identifier = identifier
        self.title = title
        self.imageText = imageText
    }
}

class ChatSettingsProfileTableViewCell: UITableViewCell {
    weak var content: UIView?

    var maxContentWidth: CGFloat {
        return self.contentView.frame.width
    }

    func setContent(content: UIView?) {
        self.content?.removeFromSuperview()

        guard let content = content else { return }
        self.contentView.addSubview(content)
        self.content = content

        let top = NSLayoutConstraint(item: self.contentView,
                                     attribute: .top,
                                     relatedBy: .equal,
                                     toItem: content,
                                     attribute: .top,
                                     multiplier: 1.0,
                                     constant: 0.0)

        let bottom = NSLayoutConstraint(item: self.contentView,
                                        attribute: .bottom,
                                        relatedBy: .equal,
                                        toItem: content,
                                        attribute: .bottom,
                                        multiplier: 1.0,
                                        constant: 0.0)

        let leading = NSLayoutConstraint(item: self.contentView,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: content,
                                         attribute: .leading,
                                         multiplier: 1.0,
                                         constant: 0.0)

        let trailing = NSLayoutConstraint(item: self.contentView,
                                          attribute: .trailing,
                                          relatedBy: .equal,
                                          toItem: content,
                                          attribute: .trailing,
                                          multiplier: 1.0,
                                          constant: 0.0)

        self.contentView.addConstraints([top, bottom, leading, trailing])
        self.contentView.setNeedsLayout()
    }
}

typealias ChatNotificationSetting = SelectableChatSetting<ChatSettingsNotificationType, String>

protocol ChatNotificationSettingsViewControllerDelegate: class {
    func chatNotificationSettingsViewController(_ controller: ChatNotificationSettingsViewController,
                                                didChangeValueOfSetting setting: ChatNotificationSetting,
                                                to newValue: ChatSettingsNotificationType)
}

class ChatNotificationSettingsViewController: UITableViewController, ValueSelectTableViewControllerDelegate {
    let cellIdentifier = "cellIdentifier"

    var notificationSettings = [ChatNotificationSetting]() {
        didSet {
            if self.isViewLoaded { self.updateWith(notificationSettings: self.notificationSettings) }
        }
    }

    weak var delegate: ChatNotificationSettingsViewControllerDelegate?
    weak var presentedValueSelectController: ValueSelectTableViewController?
    var selectedSetting: ChatNotificationSetting?

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        guard let navigationBar = navigationController?.navigationBar else { return }
        SenderCore.shared().stylePalette.customize(navigationBar)
        SenderCore.shared().stylePalette.customize(navigationItem)
    }

    func updateWith(notificationSettings: [ChatNotificationSetting]) {
        self.tableView.reloadData()
        guard let selectedSetting = self.selectedSetting else { return }
        if let updatedSelectedSetting = notificationSettings.first(where: {
            $0.identifier == selectedSetting.identifier
        }) {
            /*
                Swift cannot compare array of tuples with comparable elements by some reason.
                We will compare options using map here.
            */
            if (updatedSelectedSetting.options.map({$0.0}) != selectedSetting.options.map({$0.0}) ||
                    updatedSelectedSetting.options.map({$0.1}) != selectedSetting.options.map({$0.1}) ||
                    updatedSelectedSetting.selectedIndex != selectedSetting.selectedIndex),
               let selectController = self.presentedValueSelectController {
                self.setUpValueSelectTableViewController(selectController, withSelectedSetting: updatedSelectedSetting)
                selectController.update()
            }
            self.selectedSetting = updatedSelectedSetting
        } else {
            self.selectedSetting = nil
            self.navigationController?.popViewController(animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        let notificationsSetting = self.notificationSettings[indexPath.row]
        cell.textLabel?.text = notificationsSetting.description
        cell.detailTextLabel?.text = notificationsSetting.selectedOption.1
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationSettings.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let navigationController = self.navigationController else { return }
        let selectedSetting = self.notificationSettings[indexPath.row]
        let selectController = ValueSelectTableViewController(style: .grouped)
        self.setUpValueSelectTableViewController(selectController, withSelectedSetting: selectedSetting)
        selectController.delegate = self

        self.selectedSetting = selectedSetting
        navigationController.pushViewController(selectController, animated: true)
        self.presentedValueSelectController = selectController
    }

    func setUpValueSelectTableViewController(_ controller: ValueSelectTableViewController,
                                             withSelectedSetting selectedSetting: ChatNotificationSetting) {
        controller.title = selectedSetting.description
        controller.values = selectedSetting.options.map { $0.1 }
        controller.indexOfSelectedValue = UInt(selectedSetting.selectedIndex)
    }

    func valueSelectTableViewController(_ controller: ValueSelectTableViewController!,
                                        didFinishWithValueAt index: Int) {
        guard let selectedSetting = self.selectedSetting else { return }
        let newValue = selectedSetting.options[index].0
        self.delegate?.chatNotificationSettingsViewController(self,
                                                              didChangeValueOfSetting: selectedSetting,
                                                              to: newValue)
        self.selectedSetting = nil
    }
}

class ChatSettingsViewController: UITableViewController,
                                  ChatSettingsViewProtocol,
                                  ChatSettingsSwitchOptionTableViewCellDelegate,
                                  ChatNotificationSettingsViewControllerDelegate,
                                  ChatSettingsPhoneTableViewCellDelegate {
    let profileCellIdentifier = "ProfileCellIdentifier"
    let phoneCellIdentifier = "ChatSettingsPhoneTableViewCell"
    let switchOptionCellIdentifier = "ChatSettingsSwitchOptionTableViewCell"
    let selectOptionCellIdentifier = "ChatSettingsSelectOptionTableViewCell"

    let chatSettingsOptionIdentifierFavorite = "chatSettingsOptionIdentifierFavorite"
    let chatSettingsOptionIdentifierEncryption = "chatSettingsOptionIdentifierEncryption"
    let chatSettingsOptionIdentifierNotifications = "chatSettingsOptionIdentifierNotifications"
    let chatSettingsOptionIdentifierAddMember = "chatSettingsOptionIdentifierAddMember"

    var _presenter: ChatSettingsPresenterProtocol?
    var chat: ChatSettingsChatViewModel?
    var chatOptions: [ChatSettingsViewOption]?
    var profileView: UIView?

    var leftBarButtonItem: UIBarButtonItem?

    weak var presentedNotificationSettingsController: ChatNotificationSettingsViewController?

    let moreButton = UIBarButtonItem(image: UIImage(fromSenderFrameworkNamed:"icMore"),
                                     style: .plain,
                                     target: nil,
                                     action: nil)

    var profileSizingCell: ChatSettingsProfileTableViewCell?

    var maxProfileViewWidth: CGFloat? {
        return self.profileSizingCell?.maxContentWidth
    }

    init() {
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateWith(viewModel: ChatSettingsChatViewModel) {
        self.chat = viewModel
        var chatOptions = [ChatSettingsViewOption]()
        let favoriteOption = ChatSettingsViewOption(type: .boolean,
                                                    identifier: chatSettingsOptionIdentifierFavorite,
                                                    title: SenderFrameworkLocalizedString("chat_settings_favorite_chat"),
                                                    imageText: "⭐")
        chatOptions.append(favoriteOption)
        if viewModel.isEncryptionAvailable && viewModel.isEncryptionSettable {
            let encryptionOption = ChatSettingsViewOption(type: .boolean,
                                                          identifier: chatSettingsOptionIdentifierEncryption,
                                                          title: SenderFrameworkLocalizedString("chat_settings_encryption"),
                                                          imageText: "🔒")
            chatOptions.append(encryptionOption)
        }

        let notificationsOption = ChatSettingsViewOption(type: .select,
                                                         identifier: chatSettingsOptionIdentifierNotifications,
                                                         title: SenderFrameworkLocalizedString("chat_settings_notifications_sound"),
                                                         imageText: "🔔")
        chatOptions.append(notificationsOption)

        let addMemberOption = ChatSettingsViewOption(type: .select,
                                                     identifier: chatSettingsOptionIdentifierAddMember,
                                                     title: SenderFrameworkLocalizedString("chat_settings_add_participant"),
                                                     imageText: "👥")
        chatOptions.append(addMemberOption)
        self.chatOptions = chatOptions

        if self.isViewLoaded {
            if self.tableView.numberOfSections != self.numberOfSections(in: self.tableView) {
                self.tableView.reloadData()
            }

            self.reloadAdditionalSectionsWith(viewModel: viewModel)
            self.reloadPhonesSectionWith(viewModel: viewModel)
            self.reloadOptionsSectionWith(chatOptions: chatOptions)
            self.reloadProfileSectionWith(viewModel: viewModel)
        }

        let notificationSettings = self.chat?.chatSettings.notificationsOptions ?? []
        self.presentedNotificationSettingsController?.notificationSettings = notificationSettings
    }

    func reloadProfileSectionWith(viewModel: ChatSettingsChatViewModel?) {
        let sectionsCount = self.numberOfSections(in: self.tableView)
        let sectionsToUpdate = IndexSet((0..<sectionsCount).filter({ self.isProfileViewSection($0) }))
        guard !sectionsToUpdate.isEmpty else { return }
        UIView.performWithoutAnimation { self.tableView.reloadSections(sectionsToUpdate, with: .none) }
    }

    func reloadAdditionalSectionsWith(viewModel: ChatSettingsChatViewModel?) {
        let sectionsCount = self.numberOfSections(in: self.tableView)
        let sectionsToUpdate = IndexSet((0..<sectionsCount).filter({ self.isAdditionalSection($0) }))
        guard !sectionsToUpdate.isEmpty else { return }
        UIView.performWithoutAnimation { self.tableView.reloadSections(sectionsToUpdate, with: .none) }
    }

    func reloadPhonesSectionWith(viewModel: ChatSettingsChatViewModel?) {
        let sectionsCount = self.numberOfSections(in: self.tableView)
        let sectionsToUpdate = IndexSet((0..<sectionsCount).filter({ self.isPhonesSection($0) }))
        guard !sectionsToUpdate.isEmpty else { return }
        UIView.performWithoutAnimation { self.tableView.reloadSections(sectionsToUpdate, with: .none) }
    }

    func reloadOptionsSectionWith(chatOptions: [ChatSettingsViewOption]?) {
        let sectionsCount = self.numberOfSections(in: self.tableView)
        let sectionsToUpdate = IndexSet((0..<sectionsCount).filter({ self.isChatOptionsSection($0) }))
        guard !sectionsToUpdate.isEmpty else { return }
        UIView.performWithoutAnimation { self.tableView.reloadSections(sectionsToUpdate, with: .none) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.registerReusableViewsWith(tableView: self.tableView)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0

        let frame = CGRect(origin: .zero, size: CGSize(width: self.tableView.frame.width, height: 0.0))
        self.profileSizingCell = ChatSettingsProfileTableViewCell(style: .default, reuseIdentifier: nil)
        self.profileSizingCell?.frame = frame
        self.profileSizingCell?.layoutIfNeeded()

        self.moreButton.target = self
        self.moreButton.action = #selector(openMoreMenu)

        self.customizeNavigationBar()
        self._presenter?.viewWasLoaded()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(menuControllerDidHideMenu(notification:)),
                                               name: .UIMenuControllerDidHideMenu,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(UIResponder.becomeFirstResponder),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.moreButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        self.setNavigationBarButtons(animated: false)
    }

    func setNavigationBarButtons(animated: Bool) {
        self.navigationItem.setLeftBarButton(self.leftBarButtonItem, animated: animated)
        self.navigationItem.setRightBarButton(self.moreButton, animated: animated)
    }

    @objc open func openMoreMenu() { }

    @objc open func close() {
        self._presenter?.closeChatSettings()
    }

    open func registerReusableViewsWith(tableView: UITableView) {
        guard let senderFrameworkResourcesBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkResources bundle")
        }
        let phoneCellNib = UINib(nibName: "ChatSettingsPhoneTableViewCell",
                                 bundle: senderFrameworkResourcesBundle)
        tableView.register(phoneCellNib, forCellReuseIdentifier: phoneCellIdentifier)
        let switchOptionNib = UINib(nibName: "ChatSettingsSwitchOptionTableViewCell",
                                    bundle: senderFrameworkResourcesBundle)
        tableView.register(switchOptionNib, forCellReuseIdentifier: switchOptionCellIdentifier)
        let selectOptionNib = UINib(nibName: "ChatSettingsSelectOptionTableViewCell",
                                    bundle: senderFrameworkResourcesBundle)
        tableView.register(selectOptionNib, forCellReuseIdentifier: selectOptionCellIdentifier)
        tableView.register(ChatSettingsProfileTableViewCell.self, forCellReuseIdentifier: profileCellIdentifier)
    }

    open func customizeNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        SenderCore.shared().stylePalette.customize(navigationBar)
        SenderCore.shared().stylePalette.customize(navigationItem)
    }

    func isProfileViewSection(_ section: Int) -> Bool {
        return self.profileView != nil && section == 0
    }

    func isPhonesSection(_ section: Int) -> Bool {
        guard !(self.chat?.phoneNumbers ?? []).isEmpty else { return false }
        return self.profileView != nil ? section == 1 : section == 0
    }

    func isChatOptionsSection(_ section: Int) -> Bool {
        guard !(self.chatOptions ?? []).isEmpty else { return false }
        if !(self.chat?.phoneNumbers ?? []).isEmpty {
            return self.profileView != nil ? section == 2 : section == 1
        } else {
            return self.profileView != nil ? section == 1 : section == 0
        }
    }

    func isAdditionalSection(_ section: Int) -> Bool {
        return !self.isProfileViewSection(section) &&
               !self.isPhonesSection(section) &&
               !self.isChatOptionsSection(section)
    }

    func customizeProfileCell(_ cell: ChatSettingsProfileTableViewCell) {
        cell.setContent(content: self.profileView)
    }

    func customizePhoneCell(_ cell: ChatSettingsPhoneTableViewCell, withPhone phone: ChatSettingsPhoneViewModel) {
        /*
            Currently we don't support phone descriptions. So we will display all phones as "Work"
        */
        cell.phoneDescriptionLabel.text = SenderFrameworkLocalizedString("chat_settings_work_phone_description")
        cell.phoneLabel.text = phone.phone
        cell.delegate = self
    }

    func customizeSelectOptionCell(_ cell: ChatSettingsSelectOptionTableViewCell,
                                   withOption option: ChatSettingsViewOption) {
        cell.titleLabel.text = option.title
        cell.imageLabel.text = option.imageText
    }

    func customizeSwitchOptionCell(_ cell: ChatSettingsSwitchOptionTableViewCell,
                                   withOption option: ChatSettingsViewOption) {
        cell.titleLabel.text = option.title
        cell.imageLabel.text = option.imageText
        cell.optionSwitch.onTintColor = SenderCore.shared().stylePalette.mainAccentColor
        cell.delegate = self
        switch option.identifier {
        case chatSettingsOptionIdentifierFavorite: cell.optionSwitch.isOn = self.chat?.isFavorite ?? false
        case chatSettingsOptionIdentifierEncryption: cell.optionSwitch.isOn = self.chat?.isEncrypted ?? false
        default: break
        }
    }

    func chatSettingsSelectOptionTableViewCell(_ cell: ChatSettingsSelectOptionTableViewCell,
                                               switchValueDidChanged newValue: Bool) {
        guard let indexPath = self.tableView.indexPath(for: cell) else { return }
        guard self.isChatOptionsSection(indexPath.section) else {
            self.additionalSectionChatSettingsSelectOptionTableViewCell(cell, switchValueDidChanged: newValue)
            return
        }
        guard let option = self.chatOptions?[indexPath.row], option.type == .boolean else { return }
        self.changeValueOfSwitchOption(option, to: newValue)
    }

    func changeValueOfSwitchOption(_ option: ChatSettingsViewOption, to newValue: Bool) {
        switch option.identifier {
        case chatSettingsOptionIdentifierFavorite: self._presenter?.changeFavoriteStateTo(newValue)
        case chatSettingsOptionIdentifierEncryption: self._presenter?.changeEncryptionStateTo(newValue)
        default: break
        }
    }

    func callPhone(_ phone: ChatSettingsPhoneViewModel) {
        self._presenter?.callPhone(phone)
    }

    func selectOption(_ option: ChatSettingsViewOption) {
        switch option.identifier {
        case chatSettingsOptionIdentifierNotifications: self.showNotificationsSettings()
        case chatSettingsOptionIdentifierAddMember: self._presenter?.addParticipants()
        default: break
        }
    }

    func showNotificationsSettings() {
        guard let navigationController = self.navigationController,
              let notificationSettings = self.chat?.chatSettings.notificationsOptions else { return }
        let notificationsSettingsController = ChatNotificationSettingsViewController()
        notificationsSettingsController.notificationSettings = notificationSettings
        notificationsSettingsController.delegate = self
        notificationsSettingsController.title = SenderFrameworkLocalizedString("chat_settings_notifications_sound")
        navigationController.pushViewController(notificationsSettingsController, animated: true)
        self.presentedNotificationSettingsController = notificationsSettingsController
    }

    func chatNotificationSettingsViewController(_ controller: ChatNotificationSettingsViewController,
                                                didChangeValueOfSetting setting: ChatNotificationSetting,
                                                to newValue: ChatSettingsNotificationType) {
        self._presenter?.changeChatNotificationOption(setting, to: newValue)
    }

    //MARK : UITableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let chat = self.chat else { return  0 }
        var sectionsCount = 0
        if self.profileView != nil { sectionsCount += 1 }
        if !(chat.phoneNumbers ?? []).isEmpty { sectionsCount += 1 }
        if !(self.chatOptions ?? []).isEmpty { sectionsCount += 1 }
        sectionsCount += self.numberOfAdditionalSections()
        return sectionsCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isProfileViewSection(section) {
            return self.profileView != nil ? 1 : 0
        } else if self.isPhonesSection(section) {
            return (self.chat?.phoneNumbers ?? []).count
        } else if self.isChatOptionsSection(section) {
            return (self.chatOptions ?? []).count
        } else {
            return self.tableView(tableView, numberOfRowsInAdditionalSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isProfileViewSection(indexPath.section) {
            //We customize profile cell here, because we need to set up all constraints in order to
            //automatically calculate cell's height
            let cell = tableView.dequeueReusableCell(withIdentifier: profileCellIdentifier, for: indexPath)
            if let profileCell = cell as? ChatSettingsProfileTableViewCell { self.customizeProfileCell(profileCell) }
            return cell
        } else if self.isPhonesSection(indexPath.section) {
            let cell = tableView.dequeueReusableCell(withIdentifier: phoneCellIdentifier, for: indexPath)
            return cell
        } else if self.isChatOptionsSection(indexPath.section) {
            guard let chatOption = self.chatOptions?[indexPath.row] else {
                fatalError("Trying to get cell for unexisting chat option")
            }
            let cellIdentifier: String
            if chatOption.type == .boolean {
                cellIdentifier = switchOptionCellIdentifier
            } else {
                cellIdentifier = selectOptionCellIdentifier
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            return cell
        } else {
            return self.tableView(tableView, cellForAdditionalSectionRowAt: indexPath)
        }
    }

    //MARK : UITableView Delegate

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if self.isProfileViewSection(indexPath.section) {
        } else if self.isPhonesSection(indexPath.section) {
            if let phone = self.chat?.phoneNumbers?[indexPath.row],
               let phoneCell = cell as? ChatSettingsPhoneTableViewCell {
                self.customizePhoneCell(phoneCell, withPhone: phone)
            }
        } else if self.isChatOptionsSection(indexPath.section) {
            if let chatOption = self.chatOptions?[indexPath.row] {
                if chatOption.type == .boolean,
                   let optionCell = cell as? ChatSettingsSwitchOptionTableViewCell {
                    self.customizeSwitchOptionCell(optionCell, withOption: chatOption)
                } else if chatOption.type == .select,
                          let optionCell = cell as? ChatSettingsSelectOptionTableViewCell {
                    self.customizeSelectOptionCell(optionCell, withOption: chatOption)
                }
            }
        } else {
            return self.tableView(tableView, willDisplay: cell, forAdditionalSectionRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if self.isProfileViewSection(indexPath.section) {
            return false
        } else if self.isPhonesSection(indexPath.section) {
            return true
        } else if self.isChatOptionsSection(indexPath.section) {
            if let chatOption = self.chatOptions?[indexPath.row], chatOption.type == .select {
                return true
            } else {
                return false
            }
        } else {
            return self.tableView(tableView, shouldHighlightAdditionalSectionRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isProfileViewSection(indexPath.section) {
            tableView.deselectRow(at: indexPath, animated: true)
        } else if self.isPhonesSection(indexPath.section) {
            tableView.deselectRow(at: indexPath, animated: true)
            if let phone = self.chat?.phoneNumbers?[indexPath.row] { self.callPhone(phone) }
        } else if self.isChatOptionsSection(indexPath.section) {
            tableView.deselectRow(at: indexPath, animated: true)
            if let option = self.chatOptions?[indexPath.row], option.type == .select { self.selectOption(option) }
        } else {
            self.tableView(tableView, didSelectAdditionalSectionRowAt: indexPath)
        }
    }

    //MARK : - Additional Sections

    open func numberOfAdditionalSections() -> Int {
        return 0
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInAdditionalSection section: Int) -> Int {
        return 0
    }

    open func tableView(_ tableView: UITableView,
                        cellForAdditionalSectionRowAt
                        indexPath: IndexPath) -> UITableViewCell {
        fatalError("Subclasses of ChatSettingsViewController must override " +
                           "tableView(_:cellForAdditionalSectionRowAt:) if they use additional sections")
    }

    open func tableView(_ tableView: UITableView,
                        willDisplay cell: UITableViewCell,
                        forAdditionalSectionRowAt indexPath: IndexPath) {
    }

    open func tableView(_ tableView: UITableView, shouldHighlightAdditionalSectionRowAt indexPath: IndexPath) -> Bool {
        fatalError("Subclasses of ChatSettingsViewController must override " +
                           "tableView(_:shouldHighlightAdditionalSectionRowAt:) if they use additional sections")
    }

    open func tableView(_ tableView: UITableView, didSelectAdditionalSectionRowAt indexPath: IndexPath) {

    }

    open func additionalSectionChatSettingsSelectOptionTableViewCell(_ cell: ChatSettingsSelectOptionTableViewCell,
                                                                     switchValueDidChanged newValue: Bool) {
    }

    //MARK: - Showing "Copy" for phone cells

    var selectedPhoneCell: ChatSettingsPhoneTableViewCell?

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc func menuControllerDidHideMenu(notification: Notification) {
        self.selectedPhoneCell = nil
    }

    override func copy(_ sender: Any?) {
        guard sender != nil,
              let selectedPhoneCell = self.selectedPhoneCell,
              let phoneIndexPath = self.tableView.indexPath(for: selectedPhoneCell),
              let phone = self.chat?.phoneNumbers?[phoneIndexPath.row] else { return }
        self._presenter?.copyPhone(phone)
    }

    func chatSettingsPhoneTableViewCellDidHandleLongTap(_ cell: ChatSettingsPhoneTableViewCell) {
        self.selectedPhoneCell = cell
        let menuController = UIMenuController.shared
        let cellFrame = cell.frame
        menuController.setTargetRect(cellFrame, in: self.tableView)
        menuController.setMenuVisible(true, animated: true)
    }
}

extension ChatSettingsViewController: ModalInNavigationWireframeEventsHandler {
    func prepareForPresentationWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
        let closeImage = UIImage(fromSenderFrameworkNamed: "close")?.withRenderingMode(.alwaysTemplate)
        self.leftBarButtonItem = UIBarButtonItem(image: closeImage,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(close))
    }

    func prepareForDismissalWith(modalInNavigationWireframe: ModalInNavigationWireframe) {
    }
}
