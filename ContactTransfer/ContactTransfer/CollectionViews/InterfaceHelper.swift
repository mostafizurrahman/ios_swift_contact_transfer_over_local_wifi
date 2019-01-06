//
//  InterfaceHelper.swift
//  SocialCrop
//
//  Created by Mostafizur Rahman on 4/10/18.
//  Copyright © 2018 image-app. All rights reserved.
//

import UIKit

class InterfaceHelper: NSObject {
    
    static func animateOpacity(toInvisible animateView:UIView,
                               atDuration duratino:CGFloat,
                               onCompletion completion:@escaping (_ finished: Bool) -> Void) {
    
        if let superview = animateView.superview {
            superview.bringSubviewToFront(animateView)
            animateView.isHidden = false
            animateView.layer.opacity = 1.0
            let transform = animateView.layer.transform
            UIView.animate(withDuration: TimeInterval(duratino), animations: {
                animateView.layer.transform = CATransform3DConcat(transform, CATransform3DMakeScale(0.6, 0.6, 1.0))
                animateView.layer.opacity = 0.0
            }) { (finished) in
                superview.sendSubviewToBack(animateView)
                completion(finished)
            }
        }
    }
    
    static func animateOpacity(toVisible animateView:UIView,
                               atDuration duratino:CGFloat,
                               onCompletion completion:@escaping (_ finished: Bool) -> Void) {

        if let superview = animateView.superview {
            superview.bringSubviewToFront(animateView)
            animateView.isHidden = false
            animateView.layer.opacity = 0.0
            animateView.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0)
            UIView.animate(withDuration: TimeInterval(duratino), animations: {
                animateView.layer.opacity = 1.0
                animateView.layer.transform = CATransform3DMakeScale(1, 1, 1)
            }) { (finished) in
                completion(finished)
            }
        }
    }
    
    static public func updateView(inVisibleBound boundingRect:CGRect,
                                  forView sourceView:UIView){
        
        let sourceOrigin = sourceView.frame.origin
        let sourceSize = sourceView.frame.size
        let maskOrigin = boundingRect.origin
        let maskSize = boundingRect.size
        var originX:CGFloat = sourceOrigin.x
        var originY:CGFloat = sourceOrigin.y
        let sumS = sourceOrigin.y + sourceSize.height
        let sumM = maskOrigin.y + maskSize.height
        let sumSX = sourceOrigin.x + sourceSize.width
        let sumMX = maskOrigin.x + maskSize.width
        if sourceOrigin.x > maskOrigin.x {
            originX = maskOrigin.x
            if sourceOrigin.y > maskOrigin.y {
                originY = maskOrigin.y
            } else if sumS < sumM {
                originY += sumM - sumS
            }
        } else if sourceOrigin.y > maskOrigin.y {
            originY = maskOrigin.y
            if sourceOrigin.x > maskOrigin.x {
                originX = maskOrigin.x
            } else if sumSX < sumMX {
                originX += sumMX - sumSX
            }
        } else if sumSX < sumMX {
            originX += sumMX - sumSX
            if sumS < sumM {
                originY += sumM - sumS
            }
        } else if sumS < sumM {
            originY += sumM - sumS
            if sumSX < sumMX {
                originX += sumMX - sumSX
            }
        }
        
        let finalRect = CGRect(origin:CGPoint(x:originX, y:originY), size:sourceSize)
        
        UIView.animate(withDuration: 0.3, animations: {
            sourceView.frame = finalRect
        }) { (finished) in
            
        }
    }

}
