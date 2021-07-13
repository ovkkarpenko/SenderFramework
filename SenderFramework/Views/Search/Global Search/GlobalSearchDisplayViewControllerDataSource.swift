//
// Created by Roman Serga on 16/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc open class GlobalSearchDisplayViewControllerDataSource: NSObject,
                                                              ChatSearchManagerOutput,
                                                              GlobalSearchManagerOutput,
                                                              UITableViewDataSource {

    var searchResultModels = ArrayWithSeparator<SearchResult>()
    var tableView: UITableView

    @objc public init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView.dataSource = self
    }

    @objc open var searchResults: [EntityViewModel] {
        get {
            return searchResultModels.firstPart.flatMap({ return $0.contact })
        }
        set {
            let searchResultObjects = newValue.map({ return SearchResult(contact: $0) })
            searchResultModels.firstPart = searchResultObjects
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }

    @objc open var globalSearchResults: [GlobalSearchContactViewModel] {
        get {
            return searchResultModels.secondPart.flatMap({ return $0.contact as? GlobalSearchContactViewModel })
        }
        set {
            let searchResultObjects = newValue.map({ return SearchResult(contact: $0) })
            searchResultModels.secondPart = searchResultObjects
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }

    func searchResultForSection(_ section: Int) -> SearchResult? {
        var searchResult: SearchResult? = nil
        if section < self.searchResultModels.count {
            searchResult = self.searchResultModels[section]
        }
        return searchResult
    }

    func actionsForSection(_ section: Int) -> [ActionCellModel]? {
        return (searchResultForSection(section)?.contact as? GlobalSearchContactViewModel)?.actions
    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        return self.searchResultModels.count
    }

    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.actionsForSection(section)?.count ?? 0
    }

    @objc open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
        return cell
    }
}
