//
// Created by Roman Serga on 14/6/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import GoogleSignIn

@objc(MWURLHandler)
public class URLHandler: NSObject {

    @objc public static func application(_ application: UIKit.UIApplication,
                                   open url: URL,
                                   sourceApplication: String?,
                                   annotation: Any,
                                   senderUI: SenderUIProtocol) -> Bool {
        if url.scheme == "sender" {
            if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = urlComponents.queryItems,
               let chatID = queryItems.filter({return $0.name == "chatId"}).first?.value {
                _ = senderUI.showChatScreenWith(chatID: chatID,
                                                actions: nil,
                                                options: nil,
                                                animated: true,
                                                modally: false,
                                                delegate: nil)
                return true
            }
        }
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
}
