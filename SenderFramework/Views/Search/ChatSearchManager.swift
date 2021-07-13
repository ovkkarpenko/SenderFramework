//
//  ChatSearchManager.swift
//  SENDER
//
//  Created by Roman Serga on 30/5/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol ChatSearchManagerDelegate {
    func chatSearchManager(_ manager : ChatSearchManager, didSelectCellModel cellModel: EntityViewModel)
    func chatSearchManager(_ manager : ChatSearchManager, didSelectAction action: ActionCellModel)
}

@objc public protocol ChatSearchManagerOutput {
    var searchResults: [EntityViewModel] { get set }
}

@objc public protocol ChatSearchManagerInput {
    weak var chatSearchManager: ChatSearchManager? { get set }
}

@objc open class ChatSearchManager: NSObject {
    
    @objc open var searchController : UISearchController
    @objc open var searchDisplayController : UIViewController

    @objc open var searchManagerInput: ChatSearchManagerInput?
    @objc open var searchManagerOutput: ChatSearchManagerOutput

    @objc open weak var delegate : ChatSearchManagerDelegate?
    @objc open var localModels = [EntityViewModel]()

    @objc public init(searchDisplayController: UIViewController,
                      searchManagerOutput: ChatSearchManagerOutput,
                      searchManagerInput: ChatSearchManagerInput? = nil) {
        self.searchDisplayController = searchDisplayController
        self.searchController = UISearchController(searchResultsController: self.searchDisplayController)
        self.searchManagerOutput = searchManagerOutput
        self.searchManagerInput = searchManagerInput
        super.init()

        self.searchManagerInput?.chatSearchManager = self
        self.searchController.searchResultsUpdater = self
    }
}

extension ChatSearchManager: UISearchResultsUpdating {

    open func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text?.lowercased().trimmingCharacters(in: CharacterSet.whitespaces) {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
                let searchStringConverted = searchString.convertedToLatin()
                let localSearchResults = self.localModels.filter {
                    $0.chatTitle != nil &&
                    $0.chatTitle.lowercased().contains(searchString) ||
                    $0.chatTitleLatin != nil &&
                    $0.chatTitleLatin.lowercased().contains(searchStringConverted)
                }
                self.searchManagerOutput.searchResults = localSearchResults
            })
        }
    }

    open func chatSearchManagerInput(_ input: ChatSearchManagerInput, didSelectCellModel model: EntityViewModel) {
        self.delegate?.chatSearchManager(self, didSelectCellModel: model)
    }
}
