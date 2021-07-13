//
//  MWConsoleView.swift
//  SENDER
//
//  Created by Eugene Gilko on 5/10/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

import Foundation

class MWSubComponent: UIView {
    
    func createWith(rect: CGRect, and model: MWFormModel) -> MWSubComponent {
        return self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        self.initialize()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        self.initialize()
    }
    
    func initialize() {
        NSLog("common init")
    }
}


class MWConsoleView: UIView {
    
    func setupViewFor(maxWidth: CGFloat, model: MWFormModel) -> UIView {
        
        let baseView = addContainer(rect: CGRect(x: 0, y: 0, width: maxWidth, height: 0), and: model)
        self.addSubview(baseView)
        self.frame = baseView.frame
        
        return self;
    }
    
    /**
     Helper function to scroll to the index, section
     - parameter index: an index to scroll to
     - parameter section: a section for the index
     - parameter position: a position to scroll to
     - parameter animated: bool indicating if the scroll should be animated
     */
    
    func addContainer(rect: CGRect, and model: MWFormModel) -> MWSubComponent {
        
        var tempRect = rect
        
        var paddingView: UIView?
        var contentView: UIView?
        
        let topView = MWContainer()
        topView.createWith(rect: rect, and: model)
        
        
        if model.viewHaveMargins() {
            // first correct x-y for margins
            tempRect = fixWidth(tempRect, array: model.mMargins!)
        }
        
        if model.viewHavePadding() {
            
            paddingView! = UIView.init(frame: tempRect)
            
            // second correct x-y for padding
            tempRect = fixWidth(tempRect, array: model.mPadding!)
            
            contentView! = UIView.init(frame: tempRect)
            paddingView!.addSubview(contentView!)
            topView.addSubview(paddingView!)
        }
        else {
            
            contentView = UIView.init(frame: tempRect)
            topView.addSubview(contentView!)
        }

        // start build conteiner detail
        
        // TO DO
        
        // finish build. Fix frame for margins and padding
        
        
        
        return topView
    }
    
    
    fileprivate func fixWidth(_ rect: CGRect, array: [AnyObject]) -> CGRect {
        var tmpRect: CGRect = rect
        tmpRect.origin.x += CGFloat((array[3] as! NSString).doubleValue)
        tmpRect.origin.y += CGFloat((array[0] as! NSString).doubleValue)
        tmpRect.size.width -= (CGFloat((array[1] as! NSString).doubleValue) + CGFloat((array[3] as! NSString).doubleValue))
        return tmpRect
    }
}
