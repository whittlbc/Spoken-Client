//
//  DashSpinnerView.swift
//  Chat
//
//  Created by Ben Whittle on 1/25/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

class DashSpinnerView: NSView {
    
    private var spinnerLayer: CAShapeLayer!
        
    private var lineWidth: CGFloat!
    
    private var initialColor: NSColor!
    
    private var finalColor: NSColor!
    
    private var duration: CFTimeInterval!
        
    private var timingFunction: CAMediaTimingFunction!
    
    enum AnimationKeys {
        static let rotation = "transform.rotation"
        static let scale = "transform.scale"
        static let strokeColor = "strokeColor"
        static let lineDashPattern = "lineDashPattern"
        static let animation = "animation"
    }
    
    convenience init(
        frame frameRect: NSRect,
        lineWidth: CGFloat? = 1.75,
        initialColor: NSColor? = Color.fromRGBA(80, 90, 195, 1),
        finalColor: NSColor? = Color.fromRGBA(83, 129, 255, 1),
        duration: CFTimeInterval? = 1.1,
        timingFunction: CAMediaTimingFunction? = CAMediaTimingFunction(name: .easeInEaseOut)) {
        
        self.init(frame: frameRect)
        
        // Assign configurable styling props.
        self.lineWidth = lineWidth
        
        // Assign colors to transition to -> from.
        self.initialColor = initialColor
        self.finalColor = finalColor
        
        // Assign configurable timing props.
        self.duration = duration
        self.timingFunction = timingFunction
        
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
        spinnerLayer.strokeColor = CGColor.white
        
        // Add stroke width and make caps round.
        spinnerLayer.lineWidth = lineWidth
        spinnerLayer.lineCap = .round
        spinnerLayer.lineDashPattern = [2, 2]
    }
    
    func createScaleAnimation() -> CABasicAnimation {
        spinnerLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let scaleAnimation = CABasicAnimation(keyPath: AnimationKeys.scale)
        
        scaleAnimation.fromValue = CATransform3DMakeScale(0.8, 0.8, 1.0)
        scaleAnimation.toValue = CATransform3DMakeScale(1.0, 1.0, 1.0)
        
        scaleAnimation.duration = 0.2
        scaleAnimation.timingFunction = timingFunction
        
        scaleAnimation.repeatCount = 0
        scaleAnimation.isRemovedOnCompletion = false
        scaleAnimation.fillMode = .forwards

        return scaleAnimation
    }
    
    func createRotationAnimation() -> CABasicAnimation {
        let rotationAnimation = CABasicAnimation(keyPath: AnimationKeys.rotation)
        rotationAnimation.byValue = Float.pi * 2
        return rotationAnimation
    }
    
    func createStrokeColorAnimation() -> CABasicAnimation {
        let strokeColorAnimation = CABasicAnimation(keyPath: AnimationKeys.strokeColor)
        strokeColorAnimation.fromValue = initialColor.cgColor
        strokeColorAnimation.toValue = finalColor.cgColor
        return strokeColorAnimation
    }
    
    func createLineDashPatternAnimation() -> CABasicAnimation {
        let lineDashPatternAnimation = CABasicAnimation(keyPath: AnimationKeys.lineDashPattern)
        lineDashPatternAnimation.fromValue = [2, 2]
        lineDashPatternAnimation.toValue = [7, 6]
        return lineDashPatternAnimation
    }
    
    func createAnimationGroup() -> CAAnimationGroup {
        // Create animation group.
        let animationGroup = CAAnimationGroup()
        
        // Add rotation and stroke animations.
        animationGroup.animations = [
            createRotationAnimation(),
            createStrokeColorAnimation(),
            createLineDashPatternAnimation()
        ]
        
        // Calculate duration.
        animationGroup.duration = duration
        animationGroup.timingFunction = timingFunction
        
        // Spin forwards for forever.
        animationGroup.repeatCount = .infinity
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards
        animationGroup.autoreverses = true
        
        return animationGroup
    }
    
    // Create and add animation group to spinner layer.
    func spin() {
        spinnerLayer.add(createScaleAnimation(), forKey: AnimationKeys.scale)
        spinnerLayer.add(createAnimationGroup(), forKey: AnimationKeys.animation)
    }
}

