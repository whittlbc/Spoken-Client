//
//  NSView+Animation.swift
//  Chat
//
//  Created by Ben Whittle on 12/17/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Add animation helpers functions to view.
extension NSView {
    
    // Supported animation keys.
    enum AnimationKey {
        
        // Shadow keys.
        static let shadowOffset = "shadowOffset"
        static let shadowRadius = "shadowRadius"
        static let shadowColor = "shadowColor"
        static let shadowOpacity = "shadowOpacity"
        
        // Visibility keys.
        static let opacity = "opacity"
        
        // Background filter keys.
        static let blurRadius = "backgroundFilters.CIGaussianBlur.inputRadius"
        
        // Transform keys.
        static let scale = "transform.scale"
        
        // Color keys.
        static let backgroundColor = "backgroundColor"
    }

    func animateAsGroup(
        values: [String: Any],
        duration: CFTimeInterval,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear),
        fillMode: CAMediaTimingFillMode = CAMediaTimingFillMode.both,
        isRemovedOnCompletion: Bool = false,
        repeatCount: Float = 0,
        onLayer: CALayer? = nil,
        completionHandler: (() -> Void)? = nil) {
        
        // Resolve which layer to animate.
        let toLayer = onLayer ?? layer
        
        // Create new animation transaction.
        CATransaction.begin()
                
        // Add completion handler.
        CATransaction.setCompletionBlock(completionHandler)

        // Create and apply animations for each key/value.
        for (key, value) in values {
            if let animation = createAnimation(
                forKey: key,
                toValue: value,
                duration: duration,
                timingFunction: timingFunction,
                fillMode: fillMode,
                isRemovedOnCompletion: isRemovedOnCompletion,
                repeatCount: repeatCount
            ) {
                applyAnimation(animation, toLayer: toLayer!)
            }
        }
        
        // Commit animation transaction.
        CATransaction.commit()
    }
    
    func createAnimation(
        forKey key: String,
        toValue value: Any,
        duration: CFTimeInterval,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear),
        fillMode: CAMediaTimingFillMode = CAMediaTimingFillMode.both,
        isRemovedOnCompletion: Bool = false,
        repeatCount: Float = 0) -> CABasicAnimation? {
        
        // Create basic animation.
        let animation = CABasicAnimation(keyPath: key)
        animation.duration = duration
        animation.timingFunction = timingFunction
        animation.fillMode = fillMode
        animation.isRemovedOnCompletion = isRemovedOnCompletion
        animation.repeatCount = repeatCount
        
        // Assign new value based on type.
        switch key {
        
        // CGSize values.
        case AnimationKey.shadowOffset:
            if let val = value as? CGSize {
                animation.toValue = val
            }

        // Double values.
        case AnimationKey.shadowRadius,
             AnimationKey.shadowOpacity,
             AnimationKey.opacity,
             AnimationKey.blurRadius,
             AnimationKey.scale:
            if let val = value as? Double {
                animation.toValue = val
            }

        // CGColor values.
        case AnimationKey.shadowColor,
             AnimationKey.backgroundColor:
            animation.toValue = value as! CGColor
            
        // Return no animation if key isn't supported.
        default:
            return nil
        }
        
        return animation
    }
    
    func applyAnimation(_ animation: CABasicAnimation, toLayer: CALayer) {
        let key = animation.keyPath!
        
        switch key {
        
        // Apply layer-based animations.
        case AnimationKey.shadowOffset,
             AnimationKey.shadowRadius,
             AnimationKey.shadowColor,
             AnimationKey.shadowOpacity,
             AnimationKey.opacity,
             AnimationKey.blurRadius,
             AnimationKey.scale,
             AnimationKey.backgroundColor:
            toLayer.add(animation, forKey: key)

        default:
            break
        }
    }
}

