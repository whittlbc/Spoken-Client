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
        
        // Visibility
        static let opacity = "opacity"
    }

    func animateAsGroup(
        values: [String: Any],
        duration: CFTimeInterval,
        timingFunctionName: CAMediaTimingFunctionName = CAMediaTimingFunctionName.linear,
        fillMode: CAMediaTimingFillMode = CAMediaTimingFillMode.both,
        isRemovedOnCompletion: Bool = false,
        completionHandler: (() -> Void)? = nil) {
        
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
                timingFunctionName: timingFunctionName,
                fillMode: fillMode,
                isRemovedOnCompletion: isRemovedOnCompletion
            ) {
                applyAnimation(animation)
            }
        }
        
        // Commit animation transaction.
        CATransaction.commit()
    }
    
    func createAnimation(
        forKey key: String,
        toValue value: Any,
        duration: CFTimeInterval,
        timingFunctionName: CAMediaTimingFunctionName = CAMediaTimingFunctionName.linear,
        fillMode: CAMediaTimingFillMode = CAMediaTimingFillMode.both,
        isRemovedOnCompletion: Bool = false) -> CABasicAnimation? {
        
        // Create basic animation.
        let animation = CABasicAnimation(keyPath: key)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: timingFunctionName)
        animation.fillMode = fillMode
        animation.isRemovedOnCompletion = isRemovedOnCompletion

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
             AnimationKey.opacity:
            if let val = value as? Double {
                animation.toValue = val
            }

        // CGColor values.
        case AnimationKey.shadowColor:
            animation.toValue = value as! CGColor
            
        // Return no animation if key isn't supported.
        default:
            return nil
        }
        
        return animation
    }
    
    func applyAnimation(_ animation: CABasicAnimation) {
        let key = animation.keyPath!
        
        switch key {
        
        // Apply layer-based animations.
        case AnimationKey.shadowOffset,
             AnimationKey.shadowRadius,
             AnimationKey.shadowColor,
             AnimationKey.shadowOpacity,
             AnimationKey.opacity:
            layer?.add(animation, forKey: key)

        default:
            break
        }
    }
}

