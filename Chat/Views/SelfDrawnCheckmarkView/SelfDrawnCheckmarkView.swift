//
//  SelfDrawnCheckmarkView.swift
//  Chat
//
//  Created by Ben Whittle on 12/31/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class SelfDrawnCheckmarkView: NSView {
    
    private var checkmarkLayer: CAShapeLayer!
    
    private var color: NSColor!
    
    private var lineWidth: CGFloat!
    
    private var duration: CFTimeInterval!
        
    enum AnimationKeys {
        static let strokeEnd = "strokeEnd"
        static let animation = "animation"
    }
    
    convenience init(
        frame frameRect: NSRect,
        color: NSColor? = NSColor.black,
        lineWidth: CGFloat? = 1.5,
        duration: CFTimeInterval? = 0.15) {
        
        self.init(frame: frameRect)
        self.color = color
        self.lineWidth = lineWidth
        self.duration = duration
        
        // Make view layer based.
        setupLayer()
        
        // Add checkmark layer.
        addCheckmarkLayer()
    }
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
    }
    
    private func addCheckmarkLayer() {
        // Create checkmark layer.
        createCheckmarkLayer()
        
        // Add checkmark layer as sublayer.
        layer?.addSublayer(checkmarkLayer)
    }
    
    private func createCheckmarkLayer() {
        // Create new layer for checkmark with frame matching view's frame.
        checkmarkLayer = CAShapeLayer()
        checkmarkLayer.frame = bounds
                        
        // Create path for layer.
        checkmarkLayer.path = createCheckmarkPath()
        
        // Set initial stroke length to 0.
        checkmarkLayer.strokeEnd = 0
    
        // Make layer's background and fill color transparent.
        checkmarkLayer.backgroundColor = CGColor.clear
        checkmarkLayer.fillColor = CGColor.clear
        
        // Use checkmark color as stroke color.
        checkmarkLayer.strokeColor = color.cgColor
        
        // Add stroke width and make caps round.
        checkmarkLayer.lineWidth = lineWidth
        checkmarkLayer.lineCap = .round
        checkmarkLayer.lineJoin = .round
    }
    
    private func createCheckmarkPath() -> CGPath {
        let scale = frame.size.width / 75
        let centerX = frame.size.width / 2
        let centerY = frame.size.height / 2

        let checkmarkPath = CGMutablePath()
        
        checkmarkPath.move(to: CGPoint(x: centerX - 23 * scale, y: centerY - 1 * scale))
        checkmarkPath.addLine(to: CGPoint(x: centerX - 6 * scale, y: centerY - 15.9 * scale))
        checkmarkPath.addLine(to: CGPoint(x: centerX + 22.5 * scale, y: centerY + 16.5 * scale))
        
        return checkmarkPath
    }
        
    func createStrokeEndAnimation() -> CABasicAnimation {
        let strokeEndAnimation = CABasicAnimation(keyPath: AnimationKeys.strokeEnd)
        strokeEndAnimation.duration = duration
        strokeEndAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        strokeEndAnimation.fromValue = 0.0
        strokeEndAnimation.toValue = 1.0
        strokeEndAnimation.isRemovedOnCompletion = false
        return strokeEndAnimation
    }
    
    // Create and add animation to checkmark layer.
    func drawStroke() {
        checkmarkLayer.strokeEnd = 1.0
        checkmarkLayer.add(createStrokeEndAnimation(), forKey: AnimationKeys.animation)
    }
}
