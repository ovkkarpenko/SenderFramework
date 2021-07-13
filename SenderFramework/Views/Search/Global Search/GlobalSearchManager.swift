//
// Created by Roman Serga on 7/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc public protocol GlobalSearchManagerOutput {
    var globalSearchResults: [GlobalSearchContactViewModel] { get set }
}

@objc public protocol GlobalSearchManagerInput {
    weak var globalSearchManager: GlobalSearchManager? { get set }
}

@objc open class GlobalSearchManager: ChatSearchManager {

    @objc public var globalSearchInput: GlobalSearchManagerInput?
    var globalSearchOutput: GlobalSearchManagerOutput

    private var globalSearchTimer: Timer?

    @objc public init(globalSearchOutput: GlobalSearchManagerOutput,
                      searchDisplayController: UIViewController,
                      searchManagerOutput: ChatSearchManagerOutput,
                      globalSearchInput: GlobalSearchManagerInput? = nil,
                      searchManagerInput: ChatSearchManagerInput? = nil) {
        self.globalSearchOutput = globalSearchOutput
        self.globalSearchInput = globalSearchInput
        super.init(searchDisplayController: searchDisplayController,
                   searchManagerOutput: searchManagerOutput,
                   searchManagerInput: searchManagerInput)

        self.globalSearchInput?.globalSearchManager = self
    }

    @objc open override func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.text?.lowercased().trimmingCharacters(in: CharacterSet.whitespaces) {
            self.getGlobalSearchResultsForString(searchString)
            super.updateSearchResults(for: searchController)
        }
    }

    func getGlobalSearchResultsForString(_ string: String) {
        globalSearchTimer?.invalidate()
        globalSearchTimer = Timer.scheduledTimer(timeInterval: 1.0, target: BlockOperation {
            ServerFacade.sharedInstance().globalSearch(withText: string) {response, error in
                if let unparsedSearchResults = response?["list"] as? [[String: AnyObject]] {
                    let globalSearchResults = unparsedSearchResults.map {GlobalSearchContactViewModel(dictionary: $0)}
                    self.globalSearchOutput.globalSearchResults = globalSearchResults
                }
            }
        }, selector: #selector(BlockOperation.main), userInfo: nil, repeats: false)
    }

    @objc open func globalSearchManagerInput(_ input: ChatSearchManagerInput,
                                             didSelectAction action: ActionCellModel) {
        self.delegate?.chatSearchManager(self, didSelectAction: action)
    }
}
