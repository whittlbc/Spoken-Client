//
//  PulseView.swift
//  Chat
//
//  Created by Ben Whittle on 12/22/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class PulseView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // Make view layer-based.
        wantsLayer = true
        layer?.masksToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLayers() {
        addLayer()
    }
    
    func addLayer() {
        // Create new layer with initial frame as bounds and center position.
        let pulseLayer = CALayer()
        
        pulseLayer.frame = bounds
        
        let diameter = bounds.size.width
        let radius = diameter / 2
        
        pulseLayer.position = NSPoint(x: radius, y: radius)

        // Make it transparent and round.
        pulseLayer.backgroundColor = NSColor.blue.cgColor
        pulseLayer.masksToBounds = true
        pulseLayer.cornerRadius = radius
    
        // Add this pulse layer as a sublayer.
        layer?.addSublayer(pulseLayer)
        
        let scale = Double((MemberWindow.RecordingStyle.size.width / diameter) - 0.25)
        
        animateAsGroup(
            values: [
                AnimationKey.scale: scale,
                AnimationKey.opacity: 0.0
            ],
            duration: 1.0,
            timingFunctionName: CAMediaTimingFunctionName.easeOut,
            onLayer: pulseLayer
        )
    }
}
