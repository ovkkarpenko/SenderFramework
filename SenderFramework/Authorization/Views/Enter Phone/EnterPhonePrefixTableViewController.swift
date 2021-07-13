//
//  EnterPhonePrefixViewController.swift
//  SENDER
//
//  Created by Roman Serga on 12/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import UIKit

let countryCellID = "PhoneCountryCell"
let phoneCellID = "PhoneNumberCell"

@objc open class EnterPhoneCountryModel: NSObject, NSCoding {
    let countryName: String
    let flagImageURL: URL?
    let countryCode: String

    @objc public init(name: String, countryCode: String, flagURL: String? = nil) {
        self.countryName = name
        self.countryCode = countryCode.hasPrefix("+") ? countryCode : ("+" + countryCode)

        if let path = flagURL {
            self.flagImageURL = URL(string: path)
        } else {
            self.flagImageURL = nil
        }

        super.init()
    }

    @objc public convenience required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: "name") as? String,
              let countryCode = coder.decodeObject(forKey: "countryCode") as? String else { return nil }

        let flagURL = coder.decodeObject(forKey: "flagURL") as? String

        self.init(name: name, countryCode: countryCode, flagURL: flagURL)
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.countryName, forKey: "name")
        aCoder.encode(self.countryCode, forKey: "countryCode")
        if let urlString = self.flagImageURL?.absoluteString { aCoder.encode(urlString, forKey: "flagURL") }
    }

    @objc open override func isEqual(_ object: Any?) -> Bool {
        guard let countryModel = object as? EnterPhoneCountryModel else { return false }

        return  self.countryName == countryModel.countryName &&
                self.countryCode == countryModel.countryCode &&
                self.flagImageURL == countryModel.flagImageURL
    }
}

class EnterPhoneCountryCell: UITableViewCell {
    @IBOutlet weak var flagImageView : UIImageView!

    @IBOutlet weak var countryNameLabel : UILabel! {
        didSet {
            countryNameLabel.textColor = SenderCore.shared().stylePalette.mainTextColor
        }
    }

    @IBOutlet weak var countryCodeLabel : UILabel! {
        didSet {
            countryCodeLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }
    }
    @IBOutlet fileprivate var countryCodeLabelWidth : NSLayoutConstraint!
    @IBOutlet fileprivate weak var countryCodeLabelLeading : NSLayoutConstraint!

    var showsCountryCode : Bool = true {
        didSet {
            countryCodeLabelWidth.isActive = !showsCountryCode
            countryCodeLabelLeading.constant = showsCountryCode ? 8.0 : 0.0
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpDefaultAppearence()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpDefaultAppearence()
    }

    func setUpDefaultAppearence() {
        tintColor = SenderCore.shared().stylePalette.mainAccentColor
    }

    override func awakeFromNib() {
        countryCodeLabelWidth.constant = 0.0
    }

    func configureWithModel(_ model : EnterPhoneCountryModel) {
        if let url = model.flagImageURL {
            flagImageView.sd_setImage(with: url)
        } else {
            flagImageView.image = UIImage(fromSenderFrameworkNamed: "_default_country_flag")
        }
        countryNameLabel.text = model.countryName
        countryCodeLabel.text = model.countryCode
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }
}

class EnterPhoneNumberCell: UITableViewCell {
    @IBOutlet weak var phonePrefixLabel: UILabel! {
        didSet {
            phonePrefixLabel.textColor = SenderCore.shared().stylePalette.secondaryTextColor
        }
    }

    @IBOutlet weak var phoneTextField: UITextField! {
        didSet {
            phoneTextField.textColor = SenderCore.shared().stylePalette.mainTextColor
        }
    }

    func configureWithPrefix(_ prefix: String, phone: String) {
        phonePrefixLabel.text = prefix
        phoneTextField.text = phone
    }
}

@objc public protocol EnterPhonePrefixViewControllerDelegate {

    @objc optional func enterPhonePrefixViewController(_ controller: EnterPhonePrefixViewController,
                                                       shouldExpand expanded: Bool) -> Bool
    @objc optional func enterPhonePrefixViewController(_ controller: EnterPhonePrefixViewController,
                                                       willExpand expanded: Bool)
    @objc optional func enterPhonePrefixViewController(_ controller: EnterPhonePrefixViewController,
                                                       didExpand expanded: Bool)
}

@objc open class EnterPhonePrefixViewController: UITableViewController, UITextFieldDelegate {

    @objc open var expanded = false {

        willSet {
            if isViewLoaded {
                delegate?.enterPhonePrefixViewController?(self, willExpand: newValue)
            }
        }

        didSet {
            if isViewLoaded {
                CATransaction.setCompletionBlock {
                    self.redrawTable()
                    CATransaction.setCompletionBlock {
                        self.delegate?.enterPhonePrefixViewController?(self, didExpand: self.expanded)
                    }
                }
            }
        }
    }

    @objc open var countries = [EnterPhoneCountryModel]() {
        didSet {
            if let chosenCountry = chosenCountry {
                self.chosenCountry = countries.filter({return $0.countryCode == chosenCountry.countryCode}).first
            }
        }
    }

    @objc open var chosenCountry: EnterPhoneCountryModel?
    @objc open weak var delegate: EnterPhonePrefixViewControllerDelegate?

    fileprivate var rowModels = [EnterPhoneCountryModel]()
    fileprivate var currentPhone = ""
    fileprivate var phoneCell: EnterPhoneNumberCell? {
        return tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? EnterPhoneNumberCell
    }

    @objc open var phoneTextField: UITextField? {
        return self.phoneCell?.phoneTextField
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        self.tableView.backgroundColor = self.view.backgroundColor
        redrawTable()
        self.clearsSelectionOnViewWillAppear = false
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc open func getPhone() -> String {
        guard let prefix = phoneCell?.phonePrefixLabel.text,
              let number = phoneCell?.phoneTextField.text
                else {
            return ""
        }
        return prefix + number
    }

    func updateRowModels() {
        rowModels = (expanded && countries.count > 0) ? countries : (chosenCountry != nil ? [chosenCountry!] : [])
    }

    func countryModelForIndexPath(_ indexPath : IndexPath) -> EnterPhoneCountryModel? {
        guard (indexPath as NSIndexPath).row < rowModels.count else {
            return nil
        }
        return rowModels[(indexPath as NSIndexPath).row]
    }

    func indexPathForCountryModel(_ countryModel : EnterPhoneCountryModel) -> IndexPath? {
        guard let modelIndex = rowModels.index(of: countryModel) else {
            return nil;
        }
        return IndexPath(row: modelIndex, section: 0)
    }

    // MARK: - Table view data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowsCount = 0
        switch section {
        case 0:
            rowsCount = rowModels.count
        case 1:
            rowsCount = expanded ? 0 : 1
        default:
            rowsCount = 0
        }
        return rowsCount
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = (indexPath as NSIndexPath).section == 0 ? countryCellID : phoneCellID
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch cell {
        case let countryCell as EnterPhoneCountryCell:
            countryCell.accessoryType = expanded ? .none : .disclosureIndicator
            countryCell.showsCountryCode = expanded
            countryCell.configureWithModel(rowModels[(indexPath as NSIndexPath).row])
        case let phoneCell as EnterPhoneNumberCell:
            if let chosenCountry = self.chosenCountry {
                phoneCell.configureWithPrefix(chosenCountry.countryCode, phone: currentPhone)
            }
        default:
            break
        }
        cell.backgroundColor = SenderCore.shared().stylePalette.controllerCommonBackgroundColor
        return cell
    }

    @objc open func redrawTable() {

        //TODO: Better animation

//        tableView.beginUpdates()
//        let countryCellPaths = countries.filter({ (element) -> Bool in
//            return element.countryCode != chosenCountry.countryCode
//        }).enumerate().map(
//            {(index, element) -> NSIndexPath in
//            return NSIndexPath(forRow: index, inSection: 0)
//        })
//        let phoneCellPath = NSIndexPath(forRow: 0, inSection: 1)

        updateRowModels()
//        tableView.reloadData()
//

        tableView.reloadSections(IndexSet(integersIn: NSRange(location: 0, length: 2).toRange() ?? 0..<0), with: .top)

//        let selectedCell = tableView.cellForRowAtIndexPath(indexPathForCountryModel(chosenCountry!)!)
//
//        if expanded {
//            tableView.deleteRowsAtIndexPaths([phoneCellPath], withRowAnimation: .Automatic)
//            tableView.insertRowsAtIndexPaths(countryCellPaths, withRowAnimation: .Automatic)
//        } else {
//            tableView.insertRowsAtIndexPaths([phoneCellPath], withRowAnimation: .Automatic)
//            tableView.deleteRowsAtIndexPaths(countryCellPaths, withRowAnimation: .Automatic)
//        }
//        tableView.endUpdates()

        //TODO: Scroll to position where country row was when controller wasn't expanded
        if let chosenCountry = self.chosenCountry, expanded {
            if let selectedModelPath = indexPathForCountryModel(chosenCountry) {
//                if let selectedCell = tableView.cellForRowAtIndexPath(selectedModelPath) {
//                    var selectedCellOffset = tableView.convertRect(selectedCell.frame, toView: nil).origin
//                    selectedCellOffset.x = 0.0
//                    tableView.setContentOffset(selectedCellOffset, animated: false)
//                }
                tableView.selectRow(at: selectedModelPath, animated: false, scrollPosition: .middle)
            }
        }

        tableView.isScrollEnabled = expanded
    }

    // MARK: - Table view delegate

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 {
            if expanded {
                chosenCountry = countryModelForIndexPath(indexPath)
            }

            let newExpanded = !expanded
            let shouldExpand = delegate?.enterPhonePrefixViewController?(self, shouldExpand: newExpanded) ?? true
            if shouldExpand {
                expanded = newExpanded
            }
        }
    }

    // MARK: - Text field delegate

    open func textField(_ textField: UITextField,
                        shouldChangeCharactersIn range: NSRange,
                        replacementString string: String) -> Bool {
        if textField == self.phoneTextField {
            return ParamsFacade.sharedInstance().checkPhone(textField, range: range, replacementString: string)
        } else {
            return true
        }
    }
}
