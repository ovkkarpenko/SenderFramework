//
//  ChatSearchDisplayViewController.swift
//  SENDER
//
//  Created by Roman Serga on 30/5/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit
import SDWebImage

struct SearchResult : EmptyAble {
    var contact: EntityViewModel?
    var actions: [ActionCellModel]
    var isEmpty: Bool

    init (contact: EntityViewModel, actions:[ActionCellModel] = [], empty: Bool = false) {
        self.contact = contact
        self.actions = actions
        self.isEmpty = empty
    }
    
    init(emptyElement empty: Bool) {
        isEmpty = true
        contact = nil
        actions = []
    }
}

@objc open class ChatSearchDisplayViewController: UITableViewController {

    override open func viewDidLoad() {
        super.viewDidLoad()
        guard let senderFrameworkBundle = Bundle.senderFrameworkResources else {
            fatalError("Cannot load SenderFrameworkBundle.")
        }
        let contactNib = UINib(nibName: "ChatSearchContactHeader", bundle: senderFrameworkBundle)
        self.tableView.register(contactNib, forHeaderFooterViewReuseIdentifier: "ContactHeader")
        
        let actionNib =  UINib(nibName: "ChatSearchActionCell", bundle: senderFrameworkBundle)
        self.tableView.register(actionNib, forCellReuseIdentifier: "ActionCell")
        
        let separatorNib =  UINib(nibName: "ChatSearchSeparatorHeader", bundle: senderFrameworkBundle)
        self.tableView.register(separatorNib, forHeaderFooterViewReuseIdentifier: "SeparatorCell")

        self.view.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor

        if SenderCore.shared().stylePalette.lineColor != nil {
            self.tableView.separatorColor = SenderCore.shared().stylePalette.lineColor
        }
    }
}