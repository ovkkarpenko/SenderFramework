//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol GroupChatSettingsProfileViewDelegate: class {
    func groupChatSettingsProfileViewDidSelectAddImage(_ groupChatSettingsProfileView: GroupChatSettingsProfileView)
}

class GroupChatSettingsProfileView: ChatSettingsProfileView {
    weak var delegate: GroupChatSettingsProfileViewDelegate?

    @IBOutlet weak var addImageButton: UIButton! {
        didSet {
            self.addImageButton.setImage(UIImage(fromSenderFrameworkNamed: "_camera"), for: .normal)
            self.addImageButton.backgroundColor = .black
            self.addImageButton.alpha = 0.5
            self.addImageButton.isHidden = true
            self.addImageButton.clipsToBounds = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.addImageButton.layer.cornerRadius = self.addImageButton.frame.height / 2
    }

    override func isEditingWasSet() {
        super.isEditingWasSet()
        self.addImageButton.isHidden = !self.isEditing
    }

    @IBAction func addImageButtonPressed(_ sender: Any) {
        self.delegate?.groupChatSettingsProfileViewDidSelectAddImage(self)
    }
}
