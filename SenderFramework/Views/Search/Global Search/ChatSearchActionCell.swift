//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class ChatSearchActionCell: UITableViewCell {

    @IBOutlet weak var actionImageView: UIImageView!
    @IBOutlet weak var actionTitleLabel: UILabel! {
        didSet { actionTitleLabel.textColor = SenderCore.shared().stylePalette.mainTextColor }
    }

    var actionModel: ActionCellModel? {
        didSet {
            self.actionTitleLabel?.text = self.actionModel?.cellName
            let placeHolderImage = UIImage(fromSenderFrameworkNamed: "")
            self.actionImageView?.image = placeHolderImage
            if let imagePath = self.actionModel?.cellImageURL, let imageURL =  URL(string: imagePath) {
                self.actionImageView?.sd_setImage(with: imageURL)
            }
        }
    }
}
