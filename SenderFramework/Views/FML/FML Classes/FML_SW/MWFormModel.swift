//
//  MWFormModel.swift
//  SENDER
//
//  Created by Eugene Gilko on 5/11/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


enum MWActionList: Int {
    
    case aNone = 0
    case aCallPhone
    case aSelectUser
    case aRunRobot
    case aQrScan
    case aScanQrTo
    case aGoTo
    case aViewLink
    case aSendBtc
    case aShowBtcArhive
    case aShowBtcNotas
    case aShare
    case aShowAsQr
    case aCopy
    case aSubmitOnChange
    case aLoadFile
}

class MWFormModel: NSObject {
    
    var mPadding : Array<AnyObject>?
    var mMargins : Array<AnyObject>?
    var mActions : Array<AnyObject>?
    var mSubItems : Array<MWFormModel>?
    var mVars : Array<AnyObject>?
    var mResultingArray : Array<MWFormModel>?
    
    var mWidth : Double?
    var mHeight : Double?
    var mBSize : Double?
    var mBRadius : Double?
    var mWeight : Double?
    
    var mClassName : String?
    var mType : String?
    var mName : String?
    var mBackGround : String?
    var mValue : String?
    var mHint : String?
    var mSrc : String?
    var mState : String?
    var mTitle : String?
    var mVarType : String?
    var mBColour : String?
    var mTAlign : String?
    var mVAlign : String?
    var mHAlign : String?
    var mTextSize : String?
    var mTextColour : String?
    var mTextStyle : String?
    var mTextInputType : String?
    var mProcId : String?
    var mBitcoinAddress : String?
    
    var mCreated : Date?
    var mData : Data?
    
    var mTopModel : MWFormModel?
    
    func buildModelForMessage(_ message:Message) -> MWFormModel {
        
        self.mData = message.data
        
        if (message.procId != nil) {
            self.mProcId = message.procId;
        }
        
        let parameters: NSDictionary = ParamsFacade.sharedInstance().dictionary(from: mData!) as NSDictionary
        
        self.setupModel(parameters, topModel: nil)

        return self
    }

    func getModelClass() -> AnyClass! {
        return NSClassFromString(self.convertTypeToClass());
    }
    
    func viewHavePadding() -> Bool {
        
        return self.checkArraySumm(self.mPadding)
    }
    
    func viewHaveMargins() -> Bool {
        
        return self.checkArraySumm(self.mMargins)
    }
    
    func getCorrecteMarginsSizedRect() -> CGRect {
        return CGRect(x: 0,y: 0,width: mWidth! + self.getMarginsTotalSizeByWidth(true),height: mHeight! + self.getMarginsTotalSizeByWidth(false))
    }
    
    func getModelFont() -> UIFont {
        
        return UIFont (name: "HelveticaNeue\(mTextStyle)", size:CGFloat((mTextSize! as NSString).doubleValue))!
    }
    
    func getDataFromModel(_ calledAction:Array<AnyObject>?, calledButtonModel: MWFormModel?) -> [String:AnyObject] {
        
        if self.mTopModel != nil {
            return (self.mTopModel?.getDataFromModel(calledAction, calledButtonModel: calledButtonModel))!
        }
        
        self.mResultingArray = []
        var resultDictionary : [String:AnyObject] = [:]
        
        if self.mSubItems?.count > 0 {
            self.mResultingArray = self.getModelFromSubModels()
        }
        
        for fModel: MWFormModel in self.mResultingArray! {
            
            if fModel.mType! != "PBButtonInFormView" {
                
                if fModel.mName != nil && fModel.mValue != nil {
                    resultDictionary[fModel.mName!] = fModel.mValue! as AnyObject?
                }
            }
        }
        
        if calledAction != nil {
            
            if let testDict = self.addDataKeysFormAction(calledAction!) {
                
                resultDictionary.merge(testDict)
            }
        }
        
        if calledButtonModel != nil {
            
            if calledButtonModel!.mName != nil && calledButtonModel!.mValue != nil {
                resultDictionary[calledButtonModel!.mName!] = calledButtonModel!.mValue! as AnyObject?
            }
        }
        
        return resultDictionary
    }
    
    func findModelWithName(_ name: String?) -> MWFormModel? {
        
        if self.mTopModel != nil {
            return (self.mTopModel!.findModelWithName(name!))
        }
        
        for sModel: MWFormModel in self.mSubItems! {
            
            if sModel.mName! == name! {
                return sModel;
            }
            
            if sModel.mSubItems?.count > 0 {
                return (sModel.findModelWithName(name!))
            }
        }
        
        return nil
    }
    
    func detectAction(_ action: [String:String]) -> MWActionList {
        
        switch action["oper"]! as String {
        case "callPhone":
            return .aCallPhone
        case "selectUser":
            return .aSelectUser
        case "callRobotInP2PChat",
             "callRobot",
             "startP2PChat":
            return .aRunRobot
        case "qrScan":
            return .aQrScan
        case "scanQrTo":
            return .aScanQrTo
        case "goTo":
            return .aGoTo
        case "showAsQr":
            return .aShowAsQr
        case "viewLink":
            return .aViewLink
        case "sendBtc":
            return .aSendBtc
        case "showBtcArhive":
            return .aShowBtcArhive
        case "showBtcNotas":
            return .aShowBtcNotas
        case "share":
            return .aShare
        case "copy":
            return .aCopy
        case "submitOnChange":
            return .aSubmitOnChange
        case "chooseFile":
            return .aLoadFile
        default:
            return .aNone
        }
    }
    
    func addUserInfoToField(_ contact: Contact, modelName: String?) -> Bool {
        
        if let contactItem: Item? = contact.getSomeItem() {
            if (contactItem!.type == "phone") {
                
                if let modelForChange: MWFormModel? = self.findModelWithName(modelName!) {
                    
                    modelForChange?.mValue = contactItem!.value
                    modelForChange?.mBitcoinAddress = contact.bitcoinAddress
                }
            }
        }
        
        return true
    }

    func setNewValueToModelWithName(_ value: String?, modelName: String?) -> Bool {
        if let modelForChange: MWFormModel? = self.findModelWithName(modelName!) {
        
            modelForChange?.mValue = value!
        }
        return true
    }
    
//////// PRIVATE AREA ///////////
    
    fileprivate func setupModel(_ data: NSDictionary, topModel: MWFormModel?) -> MWFormModel {
        
        if (data["type"] != nil) {
            self.mType = data["type"] as? String
            self.mClassName = self.convertTypeToClass()
        }
        
        if topModel != nil {
            self.mTopModel = topModel
        }
        
        if (data["name"] != nil) {
            self.mName = data["name"] as? String
        }
        
        if (data["state"] != nil) {
            self.mState = data["state"] as? String
        }
        
        if (data["title"] != nil) {
            self.mTitle = data["title"] as? String
        }
        
        if (data["val"] != nil) {
            self.mValue = data["val"] as? String
        }

        if (data["bg"] != nil) {
            self.mBackGround = data["bg"] as? String
        }
        
        if (data["pd"] != nil) {
            self.mPadding = data["pd"] as? Array
        }
        
        if (data["mg"] != nil) {
            self.mMargins = data["mg"] as? Array
        }
        if (data["valign"] != nil) {
            self.mVAlign = data["valign"] as? String
        }
        if (data["halign"] != nil) {
            self.mHAlign = data["halign"] as? String
        }
        
        if (data["actions"] != nil) {
            self.mActions = data["actions"] as? Array
        }
        else if (data["action"] != nil) {
            self.mActions = [data["action"]! as AnyObject]
        }
        
        if (data["vars"] != nil) {
            self.mVars = data["vars"] as? Array
            
            if (data["vars_type"] != nil) {
                self.mVarType = data["vars_type"] as? String
            }
        }
        
        if (data["w"] != nil) {
            self.mWidth = data["w"] as? Double
        }
        
        if (data["h"] != nil) {
            self.mHeight = data["h"] as? Double
        }

        if (self.mWidth == nil && data["weight"] != nil) {
            self.mWeight = data["weight"] as? Double
        }
        
        if (data["b_size"] != nil) {
            self.mBSize = data["b_size"] as? Double
            
            if (data["b_radius"] != nil) {
                self.mBRadius = data["b_radius"] as? Double
            }
            if (data["b_color"] != nil) {
                self.mBColour = data["b_color"] as? String
            }
        }
        
        if (data["hint"] != nil) {
            self.mHint = data["hint"] as? String
        }
        
        if (topModel?.mTAlign != nil && data["talign"] == nil) {
            self.mTAlign = topModel!.mTAlign!
        }
        else if (data["talign"] != nil) {
            self.mTAlign = data["talign"] as? String
        }
        
        if (topModel?.mTextSize != nil && data["size"] == nil) {
            self.mTextSize = topModel!.mTextSize!
        }
        else if (data["size"] != nil) {
            self.mTextSize = data["size"] as? String
        }
        
        if (topModel?.mTextColour != nil && data["color"] == nil) {
            self.mTextColour = topModel!.mTextColour!
        }
        else if (data["color"] != nil) {
            self.mTextColour = data["color"] as? String
        }
        
        if (topModel?.mTextStyle != nil && data["tstyle"] == nil) {
            self.mTextStyle = topModel!.mTextStyle!
        }
        else if (data["tstyle"] != nil) {
            
            self.mTextStyle = self.converStyle(data["tstyle"] as! Array)
        }
        
        if (data["it"] != nil) {
            self.mTextInputType = data["it"] as? String
        }

        if (data["src"] != nil) {
            self.mSrc = data["scr"] as? String
        }
        
        if (data["items"] != nil) {
            
            if self.mSubItems == nil {
                self.mSubItems = []
            }
            
            if let itemsArray = data["items"] as? NSArray {
                
                self.buildModelFromSubmodelArray(itemsArray as [AnyObject], topModel: (topModel != nil) ? topModel!: self)
            }
        }
        
        return self
    }
    
    fileprivate func buildModelFromSubmodelArray(_ submodels: [AnyObject], topModel: MWFormModel) -> Void {
        for tModel in submodels {
            if let dict = tModel as? NSDictionary {
                let newSubModel = MWFormModel()
                newSubModel.setupModel(dict, topModel: topModel)
                
                self.mSubItems!.append(newSubModel)
            }
        }
    }
    
    fileprivate func checkArraySumm(_ array: Array<AnyObject>?) -> Bool {
        
        if array != nil {
            
            var checkSumm = 0
            
            for v in array! {
                
                if v.doubleValue > 0 {
                    checkSumm += 1
                }
            }
            
            if checkSumm > 0 {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func getMarginsTotalSizeByWidth(_ calulateWidth: Bool) -> Double {
        
        var totalMarginsSize = 0.0
        
        if calulateWidth { //margins for width
           totalMarginsSize = mMargins![1].doubleValue + mMargins![4].doubleValue
        }
        else {
           totalMarginsSize = mMargins![0].doubleValue + mMargins![2].doubleValue
        }
        
        return totalMarginsSize
    }
    
    fileprivate func getModelFromSubModels() -> Array<MWFormModel> {
        
        var resArr :Array<MWFormModel> = []
        resArr.append(self)
        
        for sModel: MWFormModel in self.mSubItems! {
            resArr.append(sModel)
            
            if sModel.mSubItems?.count > 0 {
                resArr.append(contentsOf: sModel.getModelFromSubModels())
            }
        }
        
        return resArr
    }
    
    fileprivate func addDataKeysFormAction(_ actions: Array<AnyObject>) -> [String:AnyObject]? {
        
        var result: [String: AnyObject] = [:]
        
        for sAction : [String: AnyObject] in actions as! Array<[String: AnyObject]> {
            
            if sAction["data"] != nil {
                for  (key,value) in sAction["data"] as! [String:String] {
                    result[key] = value as AnyObject?
                }
            }
        }
        
        if result.count > 0 {
            return result
        }
        
        return nil
    }

    fileprivate func convertTypeToClass() -> String {
        
        switch mType! {
        case "col",
             "row":
            return "ColVewContainer"
        case "text":
            return "PBInputTextView"
        case "edit":
            return "PBLabelView"
        case "img":
            return "PBImageView"
        case "check":
            return "PBCheckBoxSelectView"
        case "radio":
            return "PBRadioSelectView"
        case "select":
            return "PBSelectedView"
        case "button":
            return "PBButtonInFormView"
        case "map":
            return "PBMapView"
        case "tarea":
            return "PBTextAreaView"
        case "file":
            return "PBLabelView"
        case "web":
            return "PBWebInFormView"
        default:
            return "ColVewContainer"
        }
    }
    
    fileprivate func converStyle(_ style: Array<AnyObject>) -> String! {
        
        if style.count == 1 {
        
            switch style[0] as! String {
            case "bold":
                return "-Bold"
            case "italic":
                return "-Italic"
            case "light":
                return "-Light"
            default:
                return ""
            }
        }
        else if style.count > 1 {
            
            let comStyle: [String] = style as! Array<String>
            
            let cBold = comStyle.contains("bold")
            let cItalic = comStyle.contains("Italic")
            
            if cBold && cItalic {
                return "-BoldItalic"
            }
        }
        return ""
    }
    
    fileprivate func getMainScreenBounds() -> CGRect {
        return UIScreen.main.bounds
    }
}

extension Dictionary {
    mutating func merge<K,V>(_ dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
