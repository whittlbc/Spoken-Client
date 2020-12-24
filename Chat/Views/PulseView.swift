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
        
        // Add pulse layers.
        addLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        frame = bounds
    }
    
    func addLayers() {
        addLayer()
    }
    
    func addLayer() {
        let pulseLayer = CALayer()
        pulseLayer.frame = bounds
//        pulseLayer.contentsGravity = .resizeAspectFill

        // Make it transparent and mask it.
        pulseLayer.backgroundColor = NSColor.blue.cgColor
//        pulseLayer.masksToBounds = true
//        pulseLayer.cornerRadius = bounds.height / 2
        pulseLayer.position = NSPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    
        layer?.addSublayer(pulseLayer)
        
        animateAsGroup(
            values: [
                AnimationKey.scale: 2
//                AnimationKey.opacity: 0.0
            ],
            duration: 2,
            timingFunctionName: CAMediaTimingFunctionName.easeOut,
            onLayer: pulseLayer
        )
    }
}
