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
        layerUsesCoreImageFilters = true
                
        // Create new layer with initial frame as bounds and center position.
        let pulseLayer = CAShapeLayer()
        pulseLayer.fillRule = .evenOdd
        pulseLayer.contentsGravity = .resizeAspectFill
        
        // Set frame to this view's bounds.
        pulseLayer.frame = bounds
        
        // Calculate diameter and radius of initial pulse layer size.
        let diameter = bounds.size.width
        let radius = diameter / 2
        
        // Center position the layer.
        pulseLayer.position = NSPoint(x: radius, y: radius)

        // Make it transparent and round.
        pulseLayer.backgroundColor = CGColor.white
        pulseLayer.cornerRadius = radius
        
        // Create shadow config for layer.
        let shadowConfig = Shadow(offset: CGSize(width: 0, height: 0), radius: 2.0, opacity: 0.2)
        
        // Apply shadow config properties.
        pulseLayer.shadowOffset = shadowConfig.offset
        pulseLayer.shadowRadius = shadowConfig.radius
        pulseLayer.shadowColor = shadowConfig.color
        pulseLayer.shadowOpacity = shadowConfig.opacity
        
        pulseLayer.opacity = 0.9
        
        // Add a zero-value gaussian blur.
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: 2.0]) {
            pulseLayer.backgroundFilters = [blurFilter]
        }
        
        // Add this pulse layer as a sublayer.
        layer?.addSublayer(pulseLayer)
        
        let scale = Double((MemberWindow.RecordingStyle.size.width / diameter) - 0.5)
        
        animateAsGroup(
            values: [
                AnimationKey.scale: scale,
                AnimationKey.opacity: 0.0
            ],
            duration: 1.5,
            timingFunctionName: CAMediaTimingFunctionName.easeOut,
            isRemovedOnCompletion: true,
            repeatCount: Float.infinity,
            onLayer: pulseLayer
        )
    }
}
