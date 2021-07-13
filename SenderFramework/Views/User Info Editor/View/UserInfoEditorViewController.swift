//
// Created by Roman Serga on 13/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class UserInfoEditorViewController: UIViewController, UserInfoEditorViewProtocol, UITextFieldDelegate {
    var presenter: UserInfoEditorPresenterProtocol?
    var userNameBottomBorder: CALayer?
    var userDescBottomBorder: CALayer?

    var owner: Owner?

    @IBOutlet weak var topSpace: NSLayoutConstraint! {
        didSet {
            if #available(iOS 11, *) { topSpace.constant = 0.0 }
        }
    }

    private var isInEditMode: Bool = false {
        didSet {
            if self.isViewLoaded { self.customizeViewFor(editingMode: self.isInEditMode) }
            self.presenter?.newImageData = nil
        }
    }

    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            self.userImageView.clipsToBounds = true
        }
    }

    @IBOutlet weak var addImageButton: UIButton! {
        didSet {
            self.addImageButton.setImage(UIImage(fromSenderFrameworkNamed: "_camera"), for: .normal)
            self.addImageButton.backgroundColor = .black
            self.addImageButton.alpha = 0.5
            self.addImageButton.isHidden = true
            self.addImageButton.clipsToBounds = true
        }
    }

    @IBOutlet weak var userNameTextField: UITextField! {
        didSet {
            self.userNameTextField.textColor = SenderCore.shared().stylePalette.mainAccentColor
        }
    }
    @IBOutlet weak var userDescriptionTextField: UITextField! {
        didSet {
            self.userDescriptionTextField.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }
    }

    @IBOutlet weak var editButton: UIButton! {
        didSet {
            self.editButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
            let editImage = UIImage(fromSenderFrameworkNamed: "_edit")?.withRenderingMode(.alwaysTemplate)
            self.editButton.setImage(editImage, for: .normal)
        }
    }

    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            self.cancelButton.setTitleColor(SenderCore.shared().stylePalette.secondaryTextColor, for: .normal)
            self.cancelButton.setTitle(SenderFrameworkLocalizedString("cancel"), for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.viewWasLoaded()
        self.isInEditMode = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.addImageButton.layer.cornerRadius = self.addImageButton.frame.size.width / 2
        self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width / 2
    }

    func showInvalidDataError() {
        let alert = UIAlertController(title: SenderFrameworkLocalizedString("wrong_name_format_title"),
                                      message: SenderFrameworkLocalizedString("wrong_name_format_message"),
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: SenderFrameworkLocalizedString("ok_ios"),
                                         style: .cancel) { _ in
            self.userNameTextField.becomeFirstResponder()
        }
        alert.addAction(cancelAction)
        alert.mw_safePresentIn(viewController: self, animated: true)
    }

    func updateWith(user: Owner) {
        self.owner = user
        self.userImageView.sd_cancelCurrentImageLoad()
        let placeHolder = DefaultImageGenerator.generateDefaultImageWith(emoji: user.defaultImageEmoji,
                                                                         size: self.userImageView.frame.size,
                                                                         rounded: true,
                                                                         backgroundImageName: "icAccount")
        self.userImageView.sd_setImage(with: user.imageURL, placeholderImage: placeHolder)
        self.userNameTextField.text = user.name
        self.userDescriptionTextField.text = user.desc
    }

    @IBAction func cancelButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        self.isInEditMode = false
        self.presenter?.newImageData = nil
        self.presenter?.loadOriginalUser()
    }

    @objc func editButtonPressed(sender: UIButton) {
        self.isInEditMode = true
    }

    @objc func doneButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        self.presenter?.newName = self.userNameTextField.text ?? ""
        self.presenter?.newDescription = self.userDescriptionTextField.text
        self.presenter?.editUser()
        self.isInEditMode = false
    }

    func customizeViewFor(editingMode: Bool) {
        if editingMode {
            self.userNameTextField.isUserInteractionEnabled = true
            self.userDescriptionTextField.isUserInteractionEnabled = true

            self.editButton.setTitleColor(self.cancelButton.titleColor(for: .normal), for: .normal)
            self.editButton.setImage(nil, for: .normal)
            self.editButton.setTitle(SenderFrameworkLocalizedString("done"), for: .normal)
            self.editButton.removeTarget(self,
                                         action: #selector(UserInfoEditorViewController.editButtonPressed),
                                         for: .touchUpInside)
            self.editButton.addTarget(self,
                                      action: #selector(UserInfoEditorViewController.doneButtonPressed),
                                      for: .touchUpInside)

            cancelButton.isHidden = false
            self.addImageButton.isHidden = false

            let userNameBottomBorder = CALayer()
            userNameBottomBorder.frame = CGRect(x: CGFloat(0),
                                                y: CGFloat(self.userNameTextField.frame.size.height - 1),
                                                width: CGFloat(self.userNameTextField.frame.size.width),
                                                height: CGFloat(1))
            userNameBottomBorder.backgroundColor = SenderCore.shared().stylePalette.lineColor.withAlphaComponent(0.2).cgColor
            self.userNameBottomBorder = userNameBottomBorder
            self.userNameTextField.layer.addSublayer(userNameBottomBorder)

            let userDescBottomBorder = CALayer()
            userDescBottomBorder.frame = CGRect(x: CGFloat(0),
                                                y: CGFloat(self.userDescriptionTextField.frame.size.height - 1),
                                                width: CGFloat(self.userDescriptionTextField.frame.size.width),
                                                height: CGFloat(1))
            userDescBottomBorder.backgroundColor = SenderCore.shared().stylePalette.lineColor.withAlphaComponent(0.2).cgColor
            self.userDescBottomBorder = userDescBottomBorder
            self.userDescriptionTextField.layer.addSublayer(userDescBottomBorder)
        } else {
            self.editButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
            let editImage = UIImage(fromSenderFrameworkNamed: "_edit")?.withRenderingMode(.alwaysTemplate)
            self.editButton.setTitle(nil, for: .normal)
            self.editButton.setImage(editImage, for: .normal)
            self.editButton.removeTarget(self,
                                         action: #selector(UserInfoEditorViewController.doneButtonPressed),
                                         for: .touchUpInside)
            self.editButton.addTarget(self,
                                      action:  #selector(UserInfoEditorViewController.editButtonPressed),
                                      for: .touchUpInside)

            self.userNameTextField.isUserInteractionEnabled = false
            self.userDescriptionTextField.isUserInteractionEnabled = false
            cancelButton.isHidden = true
            self.addImageButton.isHidden = true
            userNameBottomBorder?.removeFromSuperlayer()
            userDescBottomBorder?.removeFromSuperlayer()
            userNameBottomBorder = nil
            userDescBottomBorder = nil
        }
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == self.userDescriptionTextField, let userDescriptionText = textField.text as? NSString {
            return userDescriptionText.replacingCharacters(in: range, with: string).lenght() <= 80
        } else {
            return true
        }
    }

    //MARK : - Changing Photo

    @IBAction func changeImageButtonPressed(sender: UIButton) {
        self.changeUserImage()
    }

    func changeUserImage() {
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

    func removePhoto() {
        let defaultImage: UIImage?
        if let emoji = self.owner?.defaultImageEmoji {
            defaultImage = DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                                          size: self.userImageView.frame.size,
                                                                          rounded: true,
                                                                          backgroundImageName: "icAccount")
        } else {
            defaultImage = UIImage(fromSenderFrameworkNamed: "_add_photo")
        }
        self.userImageView.image = defaultImage
        self.presenter?.newImageData = Data()
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
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .camera
        self.present(picker, animated: true, completion: nil)
    }

    func selectPhotos() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }

    func makeSquareImageWith(image: UIImage, scaledToSize newSize: CGSize) -> UIImage? {
        let imgSize = image.size
        let ratio = imgSize.width > imgSize.height ? newSize.width / imgSize.width : newSize.height / imgSize.height
        let clipRect = CGRect(x: CGFloat(0.0),
                              y: CGFloat(0.0),
                              width: ratio * imgSize.width,
                              height: ratio * imgSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        UIRectClip(clipRect)
        image.draw(in: clipRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UserInfoEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [String: Any]) {
        defer {
            navigationController?.dismiss(animated: true, completion: nil)
        }
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        let newImage = self.makeSquareImageWith(image: image,
                                                scaledToSize: CGSize(width: 400.0, height: 400.0))
        let defaultImage: UIImage?
        if let emoji = self.owner?.defaultImageEmoji {
            defaultImage = DefaultImageGenerator.generateDefaultImageWith(emoji: emoji,
                                                                          size: self.userImageView.frame.size,
                                                                          rounded: true,
                                                                          backgroundImageName: "icAccount")
        } else {
            defaultImage = UIImage(fromSenderFrameworkNamed: "_add_photo")
        }
        self.userImageView.image = newImage ?? defaultImage
        self.presenter?.newImageData = newImage != nil ? UIImageJPEGRepresentation(newImage!, 0.6) : Data()
    }
}
