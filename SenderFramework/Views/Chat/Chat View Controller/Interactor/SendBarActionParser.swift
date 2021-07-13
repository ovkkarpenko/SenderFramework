//
// Created by Roman Serga on 27/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

class SendBarActionParser {
    enum SendBarAction {
        case sendMedia(mediaType: ChatMediaType)
        case vibro
        case twitch
        case addMember
        case scanQR
        case goTo(details: [String: Any])
        case openURL(url: URL)
        case callPhone(phone: String)
        case requestRobot(details: [String: Any])
    }

    func parseActionDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        guard let operationType = actionDictionary["oper"] as? String else { return nil }
        switch operationType {
        case "sendMedia": return self.parseMediaActionDictionary(actionDictionary)
        case "addUser": return .addMember
        case "qrScan": return .scanQR
        case "goTo": return self.parseGoToActionDictionary(actionDictionary)
        case "viewLink": return self.parseViewLinkActionDictionary(actionDictionary)
        case "callPhone": return self.parseCallPhoneDictionary(actionDictionary)
        case "callRobotInP2PChat",
             "callRobot",
             "startP2PChat": return self.parseRequestRobotDictionary(actionDictionary)
        default: return nil
        }
    }

    fileprivate func parseMediaActionDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        guard let mediaType = actionDictionary["type"] as? String else { return nil }
        switch mediaType {
        case "vibro": return .vibro
        case "photo": return .sendMedia(mediaType: .photo)
        case "video": return .sendMedia(mediaType: .video)
        case "location": return .sendMedia(mediaType: .location)
        case "twitch": return .twitch
        default: return nil
        }
    }

    fileprivate func parseGoToActionDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        return .goTo(details: actionDictionary)
    }

    fileprivate func parseViewLinkActionDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        guard let path = actionDictionary["link"] as? String, let url = URL(string: path) else { return nil }
        return .openURL(url: url)
    }

    fileprivate func parseCallPhoneDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        guard let phone = actionDictionary["phone"] as? String else { return nil }
        return .callPhone(phone: phone)
    }

    fileprivate func parseRequestRobotDictionary(_ actionDictionary: [String: Any]) -> SendBarAction? {
        return .requestRobot(details: actionDictionary)
    }
}
