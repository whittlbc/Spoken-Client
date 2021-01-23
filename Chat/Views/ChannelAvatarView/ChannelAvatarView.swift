//
//  ChannelAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// View representing a channel's recipient avatar.
class ChannelAvatarView: NSView {
    
    // View styling information.
    enum Style {
        
        // Container view styling.
        enum ContainerView {
            
            // Positional styling for container view.
            enum PositionStyle {
                
                // Height of avatar relative to parent channel view.
                static let relativeHeight: CGFloat = 0.68
                
                // Absolute shift left of avatar view relative to parent channel view.
                static let leftOffset: CGFloat = -5.0
                
                
            }
            
            // Shadow styling for container view.
            enum ShadowStyle {
                
                // Default, non-raised, shadow style.
                static let grounded = Shadow(
                    offset: CGSize(width: 0, height: -1),
                    radius: 2.5,
                    opacity: 0.5
                )
                
                // Raised shadow style.
                static let raised = Shadow(
                    offset: CGSize(width: 1.0, height: -2),
                    radius: 4.5,
                    opacity: 0.5
                )
                
                // Get shadow style config for channel state.
                static func getShadow(forState state: ChannelState) -> Shadow {
                    switch state {
                    case .idle:
                        return grounded
                    case .previewing:
                        return raised
                    case .recording(_):
                        return raised
                    }
                }
            }
        }
        
        // New recording indicator styling.
        enum NewRecordingIndicator {
            
            // Positional styling for new recording indicator.
            enum PositionStyle {
                
                // Height of indicator relative to parent channel view.
                static let relativeHeight: CGFloat = 0.25
                                
                // Absolute shift of indicator relative to parent channel view.
                static let edgeOffset: CGFloat = -8.0
            }
            
            // Shadow styling for new recording indicator.
            enum ShadowStyle {
                
                // Default, non-raised, shadow style.
                static let grounded = Shadow(
                    offset: CGSize(width: 0, height: 0),
                    radius: 3.0,
                    opacity: 0.5
                )
            }
        }
        
        // Image blur layer styling.
        enum BlurLayer {
            
            // Gaussian blur input radius used when applying disabled effect.
            static let disabledBlurRadius: Double = 1.6
            
            // Gaussian blur input radius used when bluring layer behind spinner.
            static let spinBlurRadius: Double = 1.6
            
            // Opacity of black background color of blur layer.
            static let spinAlpha: CGFloat = 0.2
        }
        
        // Spinner view styling.
        enum SpinnerView {
            
            // Spinner color.
            static let color = NSColor.white
            
            // Empty gap between avatar and spinner stroke.
            static let diameter: CGFloat = 20.0
        }
        
        // Checkmark view styling.
        enum CheckmarkView {
            
            // Checkmark color.
            static let color = NSColor.white
            
            // Length of side of checkmark view.
            static let length: CGFloat = 15.0
        }
    }
    
    // Animation configuration for all child views that this view owns.
    enum AnimationConfig {
        
        // Container view animation config -- match that of channel window.
        enum ContainerView {
            static let duration = ChannelWindow.AnimationConfig.duration
            static let timingFunctionName = ChannelWindow.AnimationConfig.timingFunctionName
        }
        
        // Blur layer animation config -- match that of channel window.
        enum BlurLayer {
            static let duration = ChannelWindow.AnimationConfig.duration
            static let timingFunctionName = ChannelWindow.AnimationConfig.timingFunctionName
        }
        
        // Spinner view animation config.
        enum SpinnerView {
            static let enterDuration: CFTimeInterval = 0.2
        }
        
        // Checkmark view animation config.
        enum CheckmarkView {
            static let enterDuration: CFTimeInterval = 0.2
            static let exitDuration: CFTimeInterval = 0.2
        }
    }
    
    // Auto-layout contraint identifiers.
    enum ConstraintKeys {
        static let height = "height"
        static let width = "width"
    }

    // Parent view as channel view.
    weak var channelView: ChannelView? { superview as? ChannelView }
    
    // Bubble mouse-up event to channel view.
    override func mouseUp(with event: NSEvent) {
        channelView?.onAvatarClick()
    }

    // Get an auto-layout constraint for a given identifier.
    private func getConstraint(forIdentifier id: String) -> NSLayoutConstraint? {
        constraints.first(where: { $0.identifier == id })
    }
    
    // Get this view's auto-layout height constraint.
    private func getHeightConstraint() -> NSLayoutConstraint? {
        getConstraint(forIdentifier: ConstraintKeys.height)
    }
    
    // Get this view's auto-layout width constraint.
    private func getWidthConstraint() -> NSLayoutConstraint? {
        getConstraint(forIdentifier: ConstraintKeys.width)
    }

    // Animate diameter of avatar for given state.
    func animateSize(toDiameter diameter: CGFloat) {
        // Ensure avatar view has both a height and width constraint.
        guard let heightConstraint = getHeightConstraint(),
              let widthConstraint = getWidthConstraint() else {
            logger.error("Both height and width constraints required to animate channel avatar view size...")
            return
        }
        
        // Animate avatar to new size.
        heightConstraint.animator().constant = diameter
        widthConstraint.animator().constant = diameter
    }
}
