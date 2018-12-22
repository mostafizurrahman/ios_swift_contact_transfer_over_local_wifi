//
//  BorderButton.swift
//  SocialCrop
//
//  Created by Mostafizur Rahman on 19/11/18.
//  Copyright © 2018 image-app. All rights reserved.
//

import UIKit


@IBDesignable class BorderButton: UIButton {
    
    
    
    @IBInspectable public var borderWidth:CGFloat = 8 {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    
    
    @IBInspectable var topGColor:UIColor? {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var bottomGColor:UIColor? {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    
    
    @IBInspectable  var __backgroundColor:UIColor? = .white {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var innerGColor:UIColor = .purple{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        self.layer.backgroundColor = UIColor.clear.cgColor
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.clear(rect)
        
        
        var tr:CGFloat = 0, tg:CGFloat = 0, tb:CGFloat = 0, ta:CGFloat = 0
        var br:CGFloat = 0, bg:CGFloat = 0, bb:CGFloat = 0, ba:CGFloat = 0
        
        let gradLocationsNumber = 2
        let gradLocations:[CGFloat] = [0.0, 1.0]
        guard let _topC = self.topGColor,
            let _bottomC = self.bottomGColor else {
                return
        }
        _topC.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        _bottomC.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        
        let gradColors:[CGFloat] = [tr, tg, tb, ta, br, bg, bb, ba]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorSpace: colorSpace,
                                        colorComponents: gradColors,
                                        locations: gradLocations,
                                        count: gradLocationsNumber) else {
                                            return
        }
        
        let outerPath = UIBezierPath.init(roundedRect: rect, cornerRadius: rect.height / 2)
        context.addPath(outerPath.cgPath)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x:rect.width/2, y:0),
                                   end: CGPoint(x:rect.width/2, y:rect.height),
                                   options: .drawsAfterEndLocation)
        let innerPath = UIBezierPath.init(roundedRect: rect.insetBy(dx: self.borderWidth, dy: self.borderWidth),
                                          cornerRadius: (rect.height - self.borderWidth) / 2)
        context.addPath(innerPath.cgPath)
        context.clip()
        context.setFillColor(self.innerGColor.cgColor)
        context.fill(rect)
        
        context.fillPath()
    }
    
    
}
