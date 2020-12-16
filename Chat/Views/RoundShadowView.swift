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
    
    // General offset of shadow from center.
    var shadowOffset = CGSize(width: 0, height: -1)
    
    // Shadow blur amount.
    var shadowRadius: CGFloat = 3
    
    // Shadow color.
    var shadowColor = CGColor.black
    
    // Shadow opacity.
    var shadowOpacity: Float = 0.6
    
    override func layout() {
        super.layout()
        
        // Create new shadow.
        self.shadow = NSShadow()
        
        // Assign shadow properties.
        self.layer?.shadowOffset = shadowOffset
        self.layer?.shadowRadius = shadowRadius
        self.layer?.shadowColor = shadowColor
        self.layer?.shadowOpacity = shadowOpacity
        
        // Make shadow round.
        let roundRadius = bounds.height / 2
        
        // Create round shadow path from bezier path converted to CGPath.
        self.layer?.shadowPath = NSBezierPath(
            roundedRect: bounds,
            xRadius: roundRadius,
            yRadius: roundRadius
        ).cgPath
    }
}
