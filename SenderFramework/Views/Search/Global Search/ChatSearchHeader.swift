//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

protocol ChatSearchHeaderDelegate: class {
    func chatSearchHeaderWasSelected(_ header: ChatSearchHeader)
}

class ChatSearchHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var mainButton : UIButton!
    @IBOutlet weak var containerView : ChatCellContainerView!

    override internal var contentView: UIView {
        get {
            return containerView
        }
    }

    var section: Int?

    weak var delegate: ChatSearchHeaderDelegate?

    override func awakeFromNib() {
        /*
         * On iOS 10 UITableViewHeaderFooterView creates contentView on top of all other subviews.
         * For now we set its userInteractionEnabled to false to make our mainButton selectable.
         */
        super.contentView.isUserInteractionEnabled = false
        containerView.hidesUnread = true
    }

    var contactModel: EntityViewModel? {
        didSet {
            containerView?.cellModel = contactModel
            containerView.backgroundColor = UIColor.clear
            containerView.hidesTypeImage = true
        }
    }

    @IBAction func mainButtonClicked(_ sender: UIButton!) {
        self.delegate?.chatSearchHeaderWasSelected(self)
    }
}

class ChatSearchSeparatorHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel : UILabel! {
        didSet { titleLabel?.textColor = SenderCore.shared().stylePalette.mainAccentColor }
    }
}