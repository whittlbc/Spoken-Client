//
//  ChasingTailSpinner.swift
//  Chat
//
//  Created by Ben Whittle on 12/28/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class ChasingTailSpinnerView: NSView {
    
    private var spinnerLayer: CAShapeLayer!
    
    private var color: NSColor!
    
    private var lineWidth: CGFloat!
    
    private var strokeBeginTime: Double!
    
    private var strokeStartDuration: Double!
    
    private var strokeEndDuration: Double!
    
    private var strokeTimingFunction: CAMediaTimingFunction!
    
    enum AnimationKeys {
        static let rotation = "transform.rotation"
        static let strokeStart = "strokeStart"
        static let strokeEnd = "strokeEnd"
        static let animation = "animation"
    }
    
    convenience init(
        frame frameRect: NSRect,
        color: NSColor? = NSColor.black,
        lineWidth: CGFloat? = 1.5,
        strokeBeginTime: Double? = 0.4,
        strokeStartDuration: Double? = 1.0,
        strokeEndDuration: Double? = 0.6,
        strokeTimingFunction: CAMediaTimingFunction? = CAMediaTimingFunction(controlPoints: 0.4, 0.2, 0.4, 0.9)) {
        
        self.init(frame: frameRect)
        
        // Assign configurable styling props.
        self.color = color
        self.lineWidth = lineWidth
        
        // Assign configurable timing props.
        self.strokeBeginTime = strokeBeginTime
        self.strokeStartDuration = strokeStartDuration
        self.strokeEndDuration = strokeEndDuration
        self.strokeTimingFunction = strokeTimingFunction
        
        // Make view layer based.
        setupLayer()
        
        // Add circular spinner layer.
        addSpinnerLayer()
    }
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
        layer?.masksToBounds = false
    }
    
    private func addSpinnerLayer() {
        // Create spinner layer.
        createSpinnerLayer()
        
        // Add spinner layer as sublayer.
        layer?.addSublayer(spinnerLayer)
    }
    
    private func createSpinnerLayer() {
        // Create new layer for spinner with frame matching view's frame.
        spinnerLayer = CAShapeLayer()
        spinnerLayer.frame = bounds
                        
        // Create circular path for layer.
        spinnerLayer.path = CGPath(ellipseIn: bounds, transform: nil)
    
        // Make layer's background and fill color transparent.
        spinnerLayer.backgroundColor = CGColor.clear
        spinnerLayer.fillColor = CGColor.clear
        
        // Use spinner color as stroke color.
        spinnerLayer.strokeColor = color.cgColor
        
        // Add stroke width and make caps round.
        spinnerLayer.lineWidth = lineWidth
        spinnerLayer.lineCap = .round
    }
    
    func createRotationAnimation() -> CABasicAnimation {
        let rotationAnimation = CABasicAnimation(keyPath: AnimationKeys.rotation)
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        return rotationAnimation
        
    }
    
    func createStrokeEndAnimation() -> CABasicAnimation {
        let strokeEndAnimation = CABasicAnimation(keyPath: AnimationKeys.strokeEnd)
        strokeEndAnimation.duration = strokeEndDuration
        strokeEndAnimation.timingFunction = strokeTimingFunction
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1
        return strokeEndAnimation
    }
    
    func createStrokeStartAnimation() -> CABasicAnimation {
        let strokeStartAnimation = CABasicAnimation(keyPath: AnimationKeys.strokeStart)
        strokeStartAnimation.duration = strokeStartDuration
        strokeStartAnimation.timingFunction = strokeTimingFunction
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.beginTime = strokeBeginTime
        return strokeStartAnimation
    }
    
    func createAnimations() -> CAAnimationGroup {
        // Create animation group.
        let animationGroup = CAAnimationGroup()
        
        // Add rotation and stroke animations.
        animationGroup.animations = [
            createRotationAnimation(),
            createStrokeEndAnimation(),
            createStrokeStartAnimation()
        ]
        
        // Calculate duration.
        animationGroup.duration = strokeStartDuration + strokeBeginTime
        
        // Spin forwards for forever.
        animationGroup.repeatCount = .infinity
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards
        
        return animationGroup
    }
    
    // Create and add animation group to spinner layer.
    func spin() {
        spinnerLayer.add(createAnimations(), forKey: AnimationKeys.animation)
    }
}
