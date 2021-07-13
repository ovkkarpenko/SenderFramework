//
// Created by Roman Serga on 10/10/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class GroupChatSettingsMemberCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView! {
        didSet {
            self.userImageView.clipsToBounds = true
        }
    }

    var isDisclosureIndicatorVisible: Bool = true {
        didSet {
            self.accessoryType = self.isDisclosureIndicatorVisible ? .disclosureIndicator : .none
        }
    }

    @IBOutlet weak var titleLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        self.userImageView.layer.cornerRadius = self.userImageView.frame.size.height / 2
    }
}
