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

    // Update shadow config property with optional animation to new values.
    func updateShadow(
        toConfig config: Shadow,
        animate: Bool = false,
        duration: CFTimeInterval? = nil,
        timingFunctionName: CAMediaTimingFunctionName? = nil) {
        
        // Set shadow config to new given value.
        shadowConfig = config
        
        // Animate to new values if desired.
        if animate, let dur = duration, let timing = timingFunctionName {
            animateToShadow(duration: dur, timingFunctionName: timing)
        }
    }
    
    // Animate shadow values to those already set in shadow config.
    func animateToShadow(duration: CFTimeInterval, timingFunctionName: CAMediaTimingFunctionName) {
        animateAsGroup(
            values: [
                AnimationKey.shadowOffset: shadowConfig.offset,
                AnimationKey.shadowRadius: shadowConfig.radius,
                AnimationKey.shadowColor: shadowConfig.color,
                AnimationKey.shadowOpacity: shadowConfig.opacity
            ],
            duration: duration,
            timingFunctionName: timingFunctionName
        )
    }
}
