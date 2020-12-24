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
        pulseLayer.position = NSPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)

        // Make it transparent and round.
        pulseLayer.backgroundColor = NSColor.blue.cgColor
        pulseLayer.masksToBounds = true
        pulseLayer.cornerRadius = bounds.height / 2
    
        // Add this pulse layer as a sublayer.
        layer?.addSublayer(pulseLayer)
        
        animateAsGroup(
            values: [
                AnimationKey.scale: 2.8,
                AnimationKey.opacity: 0.0
            ],
            duration: 1.0,
            timingFunctionName: CAMediaTimingFunctionName.easeOut,
            onLayer: pulseLayer
        )
    }
}
