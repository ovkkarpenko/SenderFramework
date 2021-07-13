//
//  P2PChatSettingsProfileActionButton.swift
//  SenderFramework
//
//  Created by Roman Serga on 5/10/17.
//  Copyright © 2017 Middleware Inc. All rights reserved.
//

import UIKit

class P2PChatSettingsProfileActionButton: UIView {
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            self.titleLabel.textColor = SenderCore.shared().stylePalette.mainAccentColor
        }
    }

    @IBOutlet weak var button: UIButton! {
        didSet {
            self.button.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.button.layer.cornerRadius = self.button.frame.height / 2.0
    }
}
