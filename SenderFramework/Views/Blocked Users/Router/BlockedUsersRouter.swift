//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class BlockedUsersRouter: EntityPickerRouter {
    override func buildEntityPickerView() -> ChatPickerViewController {
        return BlockedUsersView.loadFromSenderFrameworkStoryboardWith(name: "ChatPickerViewController")
    }
}
