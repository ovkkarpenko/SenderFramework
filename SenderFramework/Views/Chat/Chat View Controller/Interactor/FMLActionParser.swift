//
// Created by Roman Serga on 8/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

enum FMLAction {
    case goTo(action: [AnyHashable: Any])
    case openURL(url: URL)
    case callPhone(phone: String)
    case requestRobot(action: [AnyHashable: Any])
    case selectUser(action: [AnyHashable: Any])
    case scanQR
    case scanQRTo(action: [AnyHashable: Any])
    case sendBitcoin(action: [AnyHashable: Any])
    case notarizeBitcoin(action: [AnyHashable: Any])
    case archiveBitcoin(action: [AnyHashable: Any])
    case share(action: [AnyHashable: Any])
    case showAsQR(action: [AnyHashable: Any])
    case changeFullVersion(action: [AnyHashable: Any])
    case copy(action: [AnyHashable: Any])
    case submitOnChange(action: [AnyHashable: Any])
    case loadFile(action: [AnyHashable: Any])
    case googleAuth(action: [AnyHashable: Any])
    case bitSignWithKey(action: [AnyHashable: Any])
    case sendLocation(action: [AnyHashable: Any])
}

class FMLActionParser {

    func parseActionDictionary(_ actionDictionary: [AnyHashable: Any]) -> FMLAction? {
        guard let operationType = actionDictionary["oper"] as? String else { return nil }
        switch operationType {
        case "selectUser": return .selectUser(action: actionDictionary)
        case "qrScan": return .scanQR
        case "scanQrTo": return .scanQRTo(action: actionDictionary)
        case "showAsQr": return .showAsQR(action: actionDictionary)
        case "goTo": return self.parseGoToActionDictionary(actionDictionary)
        case "viewLink": return self.parseViewLinkActionDictionary(actionDictionary)
        case "sendBtc": return .sendBitcoin(action: actionDictionary)
        case "showBtcArhive": return .archiveBitcoin(action: actionDictionary)
        case "showBtcNotas": return .notarizeBitcoin(action: actionDictionary)
        case "share": return .share(action: actionDictionary)
        case "copy": return .copy(action: actionDictionary)
        case "submitOnChange": return .submitOnChange(action: actionDictionary)
        case "coords": return .sendLocation(action: actionDictionary)
        case "chooseFile": return .loadFile(action: actionDictionary)
        case "reCryptKey": return .bitSignWithKey(action: actionDictionary)
        case "setGoogleToken": return .googleAuth(action: actionDictionary)
        case "fullVersion": return .changeFullVersion(action: actionDictionary)
        case "callPhone": return self.parseCallPhoneDictionary(actionDictionary)
        case "callRobotInP2PChat",
             "callRobot",
             "startP2PChat": return self.parseRequestRobotDictionary(actionDictionary)
        default: return nil
        }
    }

    fileprivate func parseCallPhoneDictionary(_ actionDictionary: [AnyHashable: Any]) -> FMLAction? {
        guard let phone = actionDictionary["phone"] as? String else { return nil }
        return .callPhone(phone: phone)
    }

    fileprivate func parseRequestRobotDictionary(_ actionDictionary: [AnyHashable: Any]) -> FMLAction? {
        return .requestRobot(action: actionDictionary)
    }

    fileprivate func parseGoToActionDictionary(_ actionDictionary: [AnyHashable: Any]) -> FMLAction? {
        return .goTo(action: actionDictionary)
    }

    fileprivate func parseViewLinkActionDictionary(_ actionDictionary: [AnyHashable: Any]) -> FMLAction? {
        guard let path = actionDictionary["link"] as? String, let url = URL(string: path) else { return nil }
        return .openURL(url: url)
    }
}
