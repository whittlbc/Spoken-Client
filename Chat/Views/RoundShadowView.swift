//
//  RoundShadowView.swift
//  Chat
//
//  Created by Ben Whittle on 12/13/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Subclass of RoundView that adds an auto-sizing drop shadow.
class RoundShadowView: RoundView {
    
    // Shadow properties to apply to view.
    var shadowConfig: Shadow!
    
    convenience init(shadowConfig: Shadow) {
        self.init(frame: NSRect())
        self.shadowConfig = shadowConfig
    }
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        
        // Add shadow to view.
        applyShadowConfig()
    }
    
    func applyShadowConfig() {
        // Create new shadow for view.
        shadow = NSShadow()
        
        // Apply shadow config properties.
        layer?.shadowOffset = shadowConfig.offset
        layer?.shadowRadius = shadowConfig.radius
        layer?.shadowColor = shadowConfig.color
        layer?.shadowOpacity = shadowConfig.opacity
        
        // Make shadow round.
        let roundRadius = bounds.height / 2
        
        // Create round shadow path from bezier path converted to CGPath.
        layer?.shadowPath = NSBezierPath(
            roundedRect: bounds,
            xRadius: roundRadius,
            yRadius: roundRadius
        ).cgPath
    }
        
    func animateShadow(opacity: Double, offset: CGSize, duration: Double) {
        CATransaction.begin()
        
        let opacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        opacityAnimation.toValue = opacity
        opacityAnimation.duration = duration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        opacityAnimation.fillMode = CAMediaTimingFillMode.both
        opacityAnimation.isRemovedOnCompletion = false

        let offsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
        offsetAnimation.toValue = offset
        offsetAnimation.duration = duration
        offsetAnimation.timingFunction = opacityAnimation.timingFunction
        offsetAnimation.fillMode = opacityAnimation.fillMode
        offsetAnimation.isRemovedOnCompletion = false

        layer?.add(offsetAnimation, forKey: offsetAnimation.keyPath!)
        layer?.add(opacityAnimation, forKey: opacityAnimation.keyPath!)
        
        CATransaction.commit()
    }

}
