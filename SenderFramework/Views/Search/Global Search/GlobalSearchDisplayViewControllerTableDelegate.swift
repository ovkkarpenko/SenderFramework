//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc open class ChatSearchDisplayViewControllerTableDelegate: NSObject,
                                                               UITableViewDelegate,
                                                               GlobalSearchManagerInput,
                                                               ChatSearchManagerInput,
                                                               ChatSearchHeaderDelegate {

    @objc public weak var globalSearchManager: GlobalSearchManager?
    @objc public weak var chatSearchManager: ChatSearchManager?

    @objc var dataSource: GlobalSearchDisplayViewControllerDataSource

    @objc public init(dataSource: GlobalSearchDisplayViewControllerDataSource) {
        self.dataSource = dataSource
        self.chatSearchManager = globalSearchManager
        super.init()
    }

    @objc open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    @objc open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let searchResult = self.dataSource.searchResultForSection(section) else { return nil }

        let header: UIView?
        if searchResult.isEmpty {
            header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorCell")
        } else {
            header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ContactHeader")
        }
        return header
    }

    @objc open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let isSeparator = self.dataSource.searchResultForSection(section)?.isEmpty else {
            return 0.0
        }
        return isSeparator ? (self.dataSource.globalSearchResults.count > 0 ? 34.0 : 0.0) : 72.0
    }

    @objc open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let contactHeader = view as? ChatSearchHeader {
            contactHeader.contactModel = self.dataSource.searchResultModels[section].contact
            contactHeader.delegate = self
            contactHeader.section = section
            contactHeader.containerView?.backgroundColor = tableView.backgroundColor
        } else if let separatorHeader = view as? ChatSearchSeparatorHeader {
            separatorHeader.titleLabel.text = SenderFrameworkLocalizedString("global_search_separator_title", comment: "")
        }
    }

    @objc open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        if let actionCell = cell as? ChatSearchActionCell, let actionModel = actionModelForIndexPath(indexPath) {
            actionCell.actionModel = actionModel
        }
    }

    @objc open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let actionModel = actionModelForIndexPath(indexPath) {
            self.globalSearchManager?.globalSearchManagerInput(self, didSelectAction: actionModel)
        }
    }

    func actionModelForIndexPath(_ indexPath: IndexPath) -> ActionCellModel? {
        var actionModel: ActionCellModel? = nil
        if let actions = self.dataSource.actionsForSection(indexPath.section) {
            if (indexPath as NSIndexPath).row < actions.count {
                actionModel = actions[indexPath.row]
            }
        }
        return actionModel
    }

    func chatSearchHeaderWasSelected(_ header: ChatSearchHeader) {
        if let section = header.section, let cellModel = dataSource.searchResultModels[section].contact {
            self.globalSearchManager?.chatSearchManagerInput(self, didSelectCellModel: cellModel)
        }
    }
}
