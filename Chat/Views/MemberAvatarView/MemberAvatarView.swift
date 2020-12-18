//
//  MemberAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// View representing a workspace member's avatar.
class MemberAvatarView: NSView {
    
    // View styling information.
    enum Style {
        
        // Positional styling.
        enum PositionStyle {
            // Height of avatar relative to parent member view.
            static let relativeHeight: CGFloat = 0.7
            
            // Absolute left shift of avatar view relative to parent member view.
            static let leftOffset: CGFloat = -5.0
        }
        
        // Shadow style configs.
        enum ShadowStyle {
            
            // Default, non-raised, shadow style.
            static let grounded = Shadow(
                offset: CGSize(width: 0, height: -1),
                radius: 3,
                opacity: 0.6
            )
            
            // Raised shadow style.
            static let raised = Shadow(
                offset: CGSize(width: 1, height: -2),
                radius: 5,
                opacity: 0.5
            )
            
            // Get shadow style config for member state.
            static func getShadow(forState state: MemberState) -> Shadow {
                switch state {
                case .idle:
                    return grounded
                case .previewing, .recording:
                    return raised
                }
            }
        }
    }
    
    // Animation configuration for all child views that this view owns.
    enum AnimationConfig {
        
        // Configuration for container view animations.
        enum ContainerView {
            static let duration = WorkspaceWindow.AnimationConfig.MemberWindows.duration
            static let timingFunctionName = WorkspaceWindow.AnimationConfig.MemberWindows.timingFunctionName
        }
    }

    // Auto-layout contraint identifiers.
    enum ConstraintKeys {
        static let height = "height"
        static let width = "width"
    }
    
    // URL string to avatar.
    var avatar = ""
    
    // Container view of avatar.
    private var containerView = RoundShadowView()
    
    // View with image content.
    private var imageView = RoundView()
    
    private func getConstraint(forIdentifier id: String) -> NSLayoutConstraint? {
        constraints.first(where: { $0.identifier == id })
    }
    
    private func getHeightConstraint() -> NSLayoutConstraint? {
        getConstraint(forIdentifier: ConstraintKeys.height)
    }
    
    private func getWidthConstraint() -> NSLayoutConstraint? {
        getConstraint(forIdentifier: ConstraintKeys.width)
    }

    // Create new container view.
    private func createContainerView() {
        // Create new round view with with drop shadow.
        containerView = RoundShadowView(shadowConfig: Style.ShadowStyle.getShadow(forState: .idle))

        // Make it layer based and allow for overflow so that shadow can be seen.
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = false
                
        // Add container view to self.
        addSubview(containerView)
    }
    
    // Set up container view auto-layout.
    private func constrainContainerView() {
        // Set up auto-layout for sizing/positioning.
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of container to 70% of self height.
            containerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: Style.PositionStyle.relativeHeight),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: Style.PositionStyle.leftOffset),
            
            // Align horizontal axes.
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    // Create new image view.
    private func createImageView() {
        // Create new round view.
        imageView = RoundView()
                
        // Make it layer based and ensure overflow is hidden.
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true

        // Add image to container.
        containerView.addSubview(imageView)
    }
    
    // Set up image view auto-layout.
    private func constrainImageView() {
        // Set up auto-layout for sizing/positioning.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix image size to container size (equal height, width, and center).
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        // Create image from avatar URL.
        let image = NSImage(byReferencing: URL(string: avatar)!)
                
        // Set image to contents of view.
        imageView.layer?.contents = image
        
        // Constrain the image's size to the view's size.
        imageView.layer?.contentsGravity = .resizeAspectFill
    }
    
    func animateToState(_ state: MemberState) {
        animateSize(toState: state)
        animateShadow(toState: state)
    }
    
    private func animateSize(toState state: MemberState) {
        // Ensure avatar view has both a height and width constraint.
        guard let heightConstraint = getHeightConstraint(), let widthConstraint = getWidthConstraint() else {
            logger.error("Both height and width constraints required to animate member avatar view size...")
            return
        }

        // Get desired avatar diameter to animate to -- use window height.
        let avatarDiameter = MemberWindow.defaultSizeForState(state).height

        // Animate avatar to new size.
        heightConstraint.animator().constant = avatarDiameter
        widthConstraint.animator().constant = avatarDiameter
    }

    private func animateShadow(toState state: MemberState) {
        // Get shadow config for state.
        let shadowConfig = Style.ShadowStyle.getShadow(forState: state)
        
        // Animate container view's shadow to new config.
        containerView.updateShadow(
            toConfig: shadowConfig,
            animate: true,
            duration: AnimationConfig.ContainerView.duration,
            timingFunctionName: AnimationConfig.ContainerView.timingFunctionName
        )
    }
    
    // Render container view.
    private func renderContainerView() {
        // Create container view.
        createContainerView()
        
        // Constrain container view.
        constrainContainerView()
    }
    
    // Render image view.
    private func renderImageView() {
        // Create image view.
        createImageView()
        
        // Constrain image view.
        constrainImageView()
    }
    
    func render() {
        // Render avatar container.
        renderContainerView()
        
        // Render avatar image.
        renderImageView()
    }
}
