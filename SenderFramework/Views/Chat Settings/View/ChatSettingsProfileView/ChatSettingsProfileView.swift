//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSettingsProfileView: UIView {
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            self.imageView.clipsToBounds = true
        }
    }

    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            self.nameTextField.placeholder = SenderFrameworkLocalizedString("chat_settings_user_name_placeholder")
            self.nameTextField.textColor = SenderCore.shared().stylePalette.mainTextColor
        }
    }

    @IBOutlet weak var descriptionTextField: UITextField! {
        didSet {
            self.descriptionTextField.placeholder = SenderFrameworkLocalizedString("chat_settings_user_description_placeholder")
            self.descriptionTextField.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }
    }

    @IBOutlet weak var userNameBottomLine: UIView! {
        didSet {
            self.userNameBottomLine.backgroundColor = SenderCore.shared().stylePalette.lineColor.withAlphaComponent(0.4)
        }
    }

    @IBOutlet weak var userDescriptionBottomLine: UIView! {
        didSet {
            self.userDescriptionBottomLine.backgroundColor = SenderCore.shared().stylePalette.lineColor.withAlphaComponent(0.4)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
    }

    var isEditing: Bool = false {
        didSet { self.isEditingWasSet() }
    }

    func isEditingWasSet() {
        self.userNameBottomLine.isHidden = !self.isEditing
        self.nameTextField.isUserInteractionEnabled = self.isEditing

        self.userDescriptionBottomLine.isHidden = !self.isEditing || !self.isDescriptionEditingEnabled
        self.descriptionTextField.isUserInteractionEnabled = self.isEditing && self.isDescriptionEditingEnabled
    }

    var isDescriptionEditingEnabled: Bool = false {
        didSet { self.isDescriptionEditingEnabledWasSet() }
    }

    func isDescriptionEditingEnabledWasSet() {
        if self.isEditing {
            self.userDescriptionBottomLine.isHidden = !self.isDescriptionEditingEnabled
            self.descriptionTextField.isUserInteractionEnabled = self.isDescriptionEditingEnabled
        }
    }
}
