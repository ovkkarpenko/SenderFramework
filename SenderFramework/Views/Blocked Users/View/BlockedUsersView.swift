//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BlockedUsersView: ChatPickerViewController {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.title = SenderFrameworkLocalizedString("act_unblock_user_ios")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = SenderFrameworkLocalizedString("act_unblock_user_ios")
    }
}
