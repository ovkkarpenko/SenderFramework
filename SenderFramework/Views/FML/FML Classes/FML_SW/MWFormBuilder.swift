//
//  MWFormBuilder.swift
//  SENDER
//
//  Created by Eugene Gilko on 5/17/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

@objc open class MWFormBuilder: NSObject {
    
    func buildViewForMessage(message:Message) -> UIView {
        
        let formModel = MWFormModel().buildModelForMessage(message)
        let formView = MWConsoleView()
        formView.setupViewFor(maxWidth: getMainScreenBounds().size.width, model: formModel)
        
        return formView
    }
    
    fileprivate func getMainScreenBounds() -> CGRect {
        return UIScreen.main.bounds
    }
}
