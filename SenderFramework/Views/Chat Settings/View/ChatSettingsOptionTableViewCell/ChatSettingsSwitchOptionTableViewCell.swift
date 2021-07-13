//
//  ChatSettingsSwitchOptionTableViewCell.swift
//  SenderFramework
//
//  Created by Roman Serga on 4/10/17.
//  Copyright © 2017 Middleware Inc. All rights reserved.
//

import UIKit

protocol ChatSettingsSwitchOptionTableViewCellDelegate: class {
    func chatSettingsSelectOptionTableViewCell(_ cell: ChatSettingsSelectOptionTableViewCell,
                                               switchValueDidChanged newValue: Bool)
}

class ChatSettingsSwitchOptionTableViewCell: ChatSettingsSelectOptionTableViewCell {

    var optionSwitch = UISwitch()

    weak var delegate: ChatSettingsSwitchOptionTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.accessoryView = self.optionSwitch
        self.optionSwitch.addTarget(self, action: #selector(self.optionSwitchValueChanged(_:)), for: .valueChanged)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func optionSwitchValueChanged(_ sender: UISwitch) {
        self.delegate?.chatSettingsSelectOptionTableViewCell(self, switchValueDidChanged: sender.isOn)
    }
}
