//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GroupChatSettingsViewController: ChatSettingsViewController,
                                       GroupChatSettingsViewProtocol,
                                       GroupChatSettingsProfileViewDelegate {
    let memberCellIdentifier = "MemberCellIdentifier"

    var presenter: GroupChatSettingsPresenterProtocol? {
        didSet { self._presenter = self.presenter }
    }

    var groupProfileView = GroupChatSettingsProfileView.mw_loadFromSenderFrameworkNibNamed("GroupChatSettingsProfileView") {
        didSet { self.profileView = profileView }
    }

    var isEditingChat: Bool = false

    let doneEditingButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
    let cancelEditingButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)

    var imageToSet: UIImage?
    var cameraManager: CameraManager?

    override func viewDidLoad() {
        self.doneEditingButton.target = self
        self.doneEditingButton.action = #selector(finishEditing)

        self.cancelEditingButton.target = self
        self.cancelEditingButton.action = #selector(cancelEditing)

        self.setIsEditingUser(false, animated: false)
        self.groupProfileView.translatesAutoresizingMaskIntoConstraints = false
        self.groupProfileView.backgroundColor = .white
        self.groupProfileView.delegate = self
        self.groupProfileView.isDescriptionEditingEnabled = false
        self.profileView = self.groupProfileView

        super.viewDidLoad()
    }

    func setIsEditingUser(_ isEditingUser: Bool, animated: Bool) {
        self.isEditingChat = isEditingUser
        self.groupProfileView.isEditing = self.isEditingChat
        self.setNavigationBarButtons(animated: animated)
    }

    override func setNavigationBarButtons(animated: Bool) {
        super.setNavigationBarButtons(animated: animated)
        if self.isEditingChat {
            self.navigationItem.setRightBarButton(self.doneEditingButton, animated: animated)
            self.navigationItem.setLeftBarButton(self.cancelEditingButton, animated: animated)
        } else {
            self.navigationItem.setRightBarButton(self.moreButton, animated: animated)
            self.navigationItem.setLeftBarButton(self.leftBarButtonItem, animated: animated)
        }
    }

    override func reloadProfileSectionWith(viewModel: ChatSettingsChatViewModel?) {
        guard !self.isEditingChat, let viewModel = viewModel else { return }
        self.groupProfileView.nameTextField.text = viewModel.title
        self.groupProfileView.descriptionTextField.text = viewModel.subtitle
        self.groupProfileView.sd_cancelCurrentImageLoad()
        let placeholder = viewModel.defaultChatAvatarWith(size: self.groupProfileView.frame.size, rounded: true)
        self.groupProfileView.imageView.sd_setImage(with: viewModel.chatAvatarURL, placeholderImage: placeholder)
    }

    override func registerReusableViewsWith(tableView: UITableView) {
        super.registerReusableViewsWith(tableView: tableView)
        let memberCellNib = UINib(nibName: "GroupChatSettingsMemberCell", bundle: .senderFrameworkResources)
        tableView.register(memberCellNib, forCellReuseIdentifier: self.memberCellIdentifier)
    }

    override func numberOfAdditionalSections() -> Int {
        return (self.chat?.members ?? []).count > 0 ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInAdditionalSection section: Int) -> Int {
        return (self.chat?.members ?? []).count
    }

    override func tableView(_ tableView: UITableView,
                            cellForAdditionalSectionRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.memberCellIdentifier, for: indexPath)
        return cell
    }

    func customizeMemberCell(_ cell: GroupChatSettingsMemberCell, withMember member: ChatSettingsMemberViewModel) {
        cell.isDisclosureIndicatorVisible = !member.isOwner
        cell.titleLabel.text = member.name
        cell.userImageView.sd_cancelCurrentImageLoad()
        let placeHolder = member.defaultAvatarWith(size: cell.userImageView.frame.size, rounded: true)
        cell.userImageView.sd_setImage(with: member.avatarURL, placeholderImage: placeHolder)
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forAdditionalSectionRowAt indexPath: IndexPath) {
        if let memberCell = cell as? GroupChatSettingsMemberCell, let members = self.chat?.members {
            let member = members[indexPath.row]
            self.customizeMemberCell(memberCell, withMember: member)
        }
    }

    override func tableView(_ tableView: UITableView,
                            shouldHighlightAdditionalSectionRowAt indexPath: IndexPath) -> Bool {
        guard let member = self.chat?.members[indexPath.row], !member.isOwner else { return false }
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectAdditionalSectionRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let member = self.chat?.members[indexPath.row], !member.isOwner else { return }
        self.presenter?.goToChatWith(member: member)
    }

    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard self.isAdditionalSection(indexPath.section),
              let member = self.chat?.members[indexPath.row], !member.isOwner else { return nil }

        let deleteAction = UITableViewRowAction(style: .destructive,
                                                title: SenderFrameworkLocalizedString("delete_ios")) { _, indexPath in
            self.deleteCellAt(indexPath: indexPath)
        }
        return [deleteAction]
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard self.isAdditionalSection(indexPath.section),
              let member = self.chat?.members[indexPath.row], !member.isOwner else { return false }
        return true
    }

    func deleteCellAt(indexPath: IndexPath) {
        guard let member = self.chat?.members[indexPath.row] else { return }
        self.presenter?.deleteMember(member)
    }

    override func openMoreMenu() {
        let editAction = UIAlertAction(title: SenderFrameworkLocalizedString("edit"),
                                       style: .default) { _ in self.startEditing() }

        let isBlockedChat = self.chat?.isBlocked ?? false
        let blockTitle = SenderFrameworkLocalizedString(isBlockedChat ? "chat_settings_unblock" : "chat_settings_block")
        let blockAction = UIAlertAction(title: blockTitle,
                                        style: .destructive) { _ in self.blockActionSelected() }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel"), style: .cancel)

        let isDeletedChat = self.chat?.isDeleted ?? true
        let isDeletableChat = self.chat?.isDeletable ?? true
        let actions: [UIAlertAction]
        if isDeletedChat || !isDeletableChat {
            actions = [editAction, blockAction, cancelAction]
        } else {
            let leaveAction = UIAlertAction(title: SenderFrameworkLocalizedString("chat_settings_leave_chat"),
                                            style: .destructive) { _ in self.leaveActionSelected() }
            actions = [editAction, blockAction, leaveAction, cancelAction]
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actions.forEach { alertController.addAction($0) }
        alertController.mw_safePresentIn(viewController: self, animated: true)
    }

    func blockActionSelected() {
        guard let isBlocked = self.chat?.isBlocked else { return }
        self.presenter?.changeBlockStateTo(!isBlocked)
    }

    func leaveActionSelected() {
        self.presenter?.leaveChat()
    }

    func startEditing() {
        self.setIsEditingUser(true, animated: true)
    }

    @objc func finishEditing() {
        self.setIsEditingUser(false, animated: true)
        self.presenter?.editWith(name: self.groupProfileView.nameTextField.text,
                                 description: self.groupProfileView.descriptionTextField.text,
                                 image: self.imageToSet)
    }

    @objc func cancelEditing() {
        self.setIsEditingUser(false, animated: true)
        self.imageToSet = nil
        if let chat = self.chat { self.updateWith(viewModel: chat) }
    }

    func groupChatSettingsProfileViewDidSelectAddImage(_ groupChatSettingsProfileView: GroupChatSettingsProfileView) {
        self.view.endEditing(true)

        let alert = UIAlertController(title: SenderFrameworkLocalizedString("change_photo"),
                                      message: nil,
                                      preferredStyle: .actionSheet)

        let selectFromGalleryAction = UIAlertAction(title: SenderFrameworkLocalizedString("select_from_gallery"),
                                                    style: .default) { action in
            self.selectPhotos()
        }

        let takePhotoAction = UIAlertAction(title: SenderFrameworkLocalizedString("take_photo"),
                                            style: .default) { action in
            self.takePhoto()
        }

        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("cancel"),
                                         style: .cancel) { action in
        }

        let removePhotoAction = UIAlertAction(title: SenderFrameworkLocalizedString("remove_photo"),
                                              style: .destructive) { action in
            self.removePhoto()
        }

        alert.addAction(selectFromGalleryAction)
        alert.addAction(takePhotoAction)
        alert.addAction(removePhotoAction)
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: self, animated: true)
    }

    func takePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: SenderFrameworkLocalizedString("error_ios"),
                                          message: SenderFrameworkLocalizedString("device_without_camera_ios"),
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"), style: .cancel)
            alert.addAction(okAction)
            alert.popoverPresentationController?.sourceView = self.view
            alert.mw_safePresentIn(viewController: self, animated: true)
            return
        }
        self.cameraManager = CameraManager(parentController: self, chat: nil)
        self.cameraManager?.delegate = self
        self.cameraManager?.showCamera()
    }

    func removePhoto() {
        self.imageToSet = UIImage()
        let placeHolder = self.chat?.defaultChatAvatarWith(size: self.groupProfileView.imageView.frame.size,
                                                           rounded: true)
        self.groupProfileView.imageView.image = placeHolder
    }

    func selectPhotos() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }
}

extension GroupChatSettingsViewController: CameraManagerDelegate {
    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPicking image: UIImage?,
                       withAssetID assetID: String?) {
        self.imageToSet = image
        self.groupProfileView.imageView.image = image
        self.dismiss(animated: true)
        self.cameraManager = nil
    }

    func cameraManager(_ cameraManager: CameraManager!,
                       didFinishPickingVideoWithAssetID assetID: String!,
                       duration: TimeInterval) {
        self.dismiss(animated: true)
        self.cameraManager = nil
    }

    func cameraManagerDidFinishWithError(_ error: Error!) {
        self.dismiss(animated: true)
        self.cameraManager = nil
    }
}

extension GroupChatSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [String: Any]) {
        defer {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        self.imageToSet = image
        self.groupProfileView.imageView.image = image
    }
}
