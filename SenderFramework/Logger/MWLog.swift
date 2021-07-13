//
//  MWLog.swift
//  SENDER
//
//  Created by Eugene Gilko on 7/2/15.
//  Copyright © 2015 MiddleWare. All rights reserved.
//

import Foundation

class MWLog {
    
    class func printLog(_ objects: AnyObject?...) {
        
        /* MUTE FOR PRODUCTION */
        
        print("\n------------------------------\n")
        print(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .long))
        for obj in objects {
            print(obj)
        }
        print("\n------------------------------\n")
    }
}
