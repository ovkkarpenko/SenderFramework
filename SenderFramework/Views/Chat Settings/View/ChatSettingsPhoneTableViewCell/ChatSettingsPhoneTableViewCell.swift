//
// Created by Roman Serga on 4/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//
import UIKit

protocol ChatSettingsPhoneTableViewCellDelegate: class {
    func chatSettingsPhoneTableViewCellDidHandleLongTap(_ cell: ChatSettingsPhoneTableViewCell)
}

class ChatSettingsPhoneTableViewCell: UITableViewCell {
    @IBOutlet weak var phoneDescriptionLabel: UILabel! {
        didSet {
            self.phoneDescriptionLabel.textColor = SenderCore.shared().stylePalette.mainAccentColor
        }
    }
    @IBOutlet weak var phoneLabel: UILabel!
    weak var delegate: ChatSettingsPhoneTableViewCellDelegate?

    var longPressRecognizer: UILongPressGestureRecognizer!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:)))
        self.contentView.addGestureRecognizer(self.longPressRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func handleLongTap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            self.delegate?.chatSettingsPhoneTableViewCellDidHandleLongTap(self)
        }
    }
}
