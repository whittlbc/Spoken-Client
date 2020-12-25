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
        
        // Container view styling.
        enum ContainerView {
            
            // Positional styling for container view.
            enum PositionStyle {
                
                // Height of avatar relative to parent member view.
                static let relativeHeight: CGFloat = 0.7
                
                // Absolute shift left of avatar view relative to parent member view.
                static let leftOffset: CGFloat = -5.0
            }
            
            // Shadow styling for container view.
            enum ShadowStyle {
                
                // Default, non-raised, shadow style.
                static let grounded = Shadow(
                    offset: CGSize(width: 0, height: -1),
                    radius: 3.0,
                    opacity: 0.6
                )
                
                // Raised shadow style.
                static let raised = Shadow(
                    offset: CGSize(width: 1, height: -2),
                    radius: 5.0,
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
        
        // New recording indicator styling.
        enum NewRecordingIndicator {
            
            // Positional styling for new recording indicator.
            enum PositionStyle {
                
                // Height of indicator relative to parent member view.
                static let relativeHeight: CGFloat = 0.25
                                
                // Absolute shift of indicator relative to parent member view.
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
            
            // Input radius of gaussian blur.
            static let blurRadius = 1.6
        }
    }
    
    // Animation configuration for all child views that this view owns.
    enum AnimationConfig {
        
        // Container view animation config.
        enum ContainerView {
            static let duration = WorkspaceWindow.AnimationConfig.MemberWindows.duration
            static let timingFunctionName = WorkspaceWindow.AnimationConfig.MemberWindows.timingFunctionName
        }
        
        // Image blur layer animation config.
        enum BlurLayer {
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
    
    // New recording indicator icon.
    private var newRecordingIndicator: RoundShadowView?
    
    // Pulsing animation view.
    private var pulseView: PulseView?
    
    // Blur layer to fade-in when member is disabled.
    private var blurLayer: CALayer?
        
    // Handle mouse up event.
    override func mouseUp(with event: NSEvent) {
        // Bubble up event to parent member view.
        if let parent = getMemberView() {
            parent.onAvatarClick()
        }
    }
    
    // Style self and subviews for recording animations.
    func addRecordingStyle() {
//        // Upsert pulse view.
//        pulseView = pulseView ?? createPulseView()
    }
    
    // Remove style added for recording animations.
    func removeRecordingStyle() {
//        // Remove pulse view if it exists.
//        if pulseView != nil {
//            pulseView!.removeFromSuperview()
//            pulseView = nil
//        }
    }
    
    // Get parent MemberView.
    private func getMemberView() -> MemberView? {
        superview as? MemberView
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

    // Create new container view.
    private func createContainerView() {
        // Create new round view with with drop shadow.
        containerView = RoundShadowView(
            shadowConfig: Style.ContainerView.ShadowStyle.getShadow(forState: .idle)
        )

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
            // Set height of container.
            containerView.heightAnchor.constraint(
                equalTo: heightAnchor,
                multiplier: Style.ContainerView.PositionStyle.relativeHeight
            ),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Center-align axes.
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
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
        
        // Allow the image view to respond to filters added to it.
        imageView.layerUsesCoreImageFilters = true
    }
    
    // Create new recording indicator icon.
    private func createNewRecordingIndicator() -> RoundShadowView {
        // Create new round view with with drop shadow.
        let indicator = RoundShadowView(
            shadowConfig: Style.NewRecordingIndicator.ShadowStyle.grounded
        )
        
        // Make it layer based and start it as hidden.
        indicator.wantsLayer = true
        indicator.layer?.masksToBounds = false
        indicator.alphaValue = 0
        
        // Add indicator as subview above container view.
        addSubview(indicator, positioned: NSWindow.OrderingMode.above, relativeTo: containerView)
        
        // Add auto-layout constraints to indicator.
        constrainNewRecordingIndicator(indicator)

        // Set icon as the contents of the view.
        indicator.layer?.contents = Icon.plusCircle
        
        // Constrain the icon's image size to the view's size.
        indicator.layer?.contentsGravity = .resizeAspectFill

        // Assign new indicator to instance property.
        newRecordingIndicator = indicator
        
        // Return newly created, unwrapped, view.
        return newRecordingIndicator!
    }
    
    // Set up new-recording indicator auto-layout.
    private func constrainNewRecordingIndicator(_ indicator: RoundShadowView) {
        // Set up auto-layout for sizing/positioning.
        indicator.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of indicator.
            indicator.heightAnchor.constraint(
                equalTo: heightAnchor,
                multiplier: Style.NewRecordingIndicator.PositionStyle.relativeHeight
            ),
            
            // Keep indicator height and width the same.
            indicator.widthAnchor.constraint(equalTo: indicator.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            indicator.rightAnchor.constraint(
                equalTo: rightAnchor,
                constant: Style.NewRecordingIndicator.PositionStyle.edgeOffset
            ),
            
            // Align bottom sides (but shift it up the specified amount).
            indicator.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: Style.NewRecordingIndicator.PositionStyle.edgeOffset
            ),
        ])
    }
    
    // Create new blur layer and add it as a sublayer to image view.
    private func createBlurLayer() -> CALayer {
        // Create new layer the size of image view.
        let blur = CALayer()
        blur.frame = imageView.bounds
        blur.contentsGravity = .resizeAspectFill

        // Make it transparent and mask it.
        blur.backgroundColor = NSColor.clear.cgColor
        blur.masksToBounds = true
        
        // Add a zero-value gaussian blur.
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: 0]) {
            blur.backgroundFilters = [blurFilter]
        }
        
        // Assign new blur layer to instance property.
        blurLayer = blur
        
        // Add blur layer as sublayer to image view.
        imageView.layer?.addSublayer(blur)
                
        return blur
    }

    private func createPulseView() -> PulseView {
        // Start pulse view frame as the dimensions of container view.
        let pulseDim = containerView.frame.size.height
        
        // Create new pulse view animation.
        let pulse = PulseView(frame: NSRect(x: 0, y: 0, width: pulseDim, height: pulseDim))

        // Add pulse view as a subview below container view.
        addSubview(pulse, positioned: NSWindow.OrderingMode.below, relativeTo: containerView)
        
        // Add pulse view constraints.
        constrainPulseView(pulse)
        
        // Assign new PulseView to instance method.
        pulseView = pulse

        pulseView?.addLayers()
        
        return pulse
    }
    
    // Set up new-recording indicator auto-layout.
    private func constrainPulseView(_ pulse: PulseView) {
        // Set up auto-layout for sizing/positioning.
        pulse.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of pulse view.
            pulse.heightAnchor.constraint(
                equalTo: heightAnchor,
                multiplier: Style.ContainerView.PositionStyle.relativeHeight
            ),
            
            // Keep pulse view height and width the same.
            pulse.widthAnchor.constraint(equalTo: pulse.heightAnchor),
            
            // Align center axes.
            pulse.centerXAnchor.constraint(equalTo: centerXAnchor),
            pulse.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    // Animate self and subviews due to state change.
    func animateToState(_ state: MemberState, isDisabled: Bool) {
        // Animate this view's size.
        animateSize(toState: state)
        
        // Animate this view's subviews.
        animateSubviews(toState: state, isDisabled: isDisabled)
    }
    
    // Animate diameter of avatar for given state.
    private func animateSize(toState state: MemberState) {
        // Ignore size changes to recording state.
        if state == .recording {
            return
        }
        
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

    // Animate this view's subviews for a given state.
    private func animateSubviews(toState state: MemberState, isDisabled: Bool) {
        // Animate container subview.
        animateContainerView(toState: state)
        
        // Animate image subview.
        animateImageView(isDisabled: isDisabled)
        
        // Animate "new recording" indicator.
        animateNewRecordingIndicator(toState: state)
    }
    
    // Toggle the amount of drop shadow for container view based on state.
    private func animateContainerView(toState state: MemberState) {
        // Create new shadow config for state.
        let shadowConfig = Style.ContainerView.ShadowStyle.getShadow(forState: state)
        
        // Animate container view's shadow to new config.
        containerView.updateShadow(
            toConfig: shadowConfig,
            animate: true,
            duration: AnimationConfig.ContainerView.duration,
            timingFunctionName: AnimationConfig.ContainerView.timingFunctionName
        )
    }
    
    // Toggle blur layer based on disabled status of member.
    private func animateImageView(isDisabled: Bool) {
        isDisabled ? fadeInBlurLayer() : fadeOutBlurLayer()
    }
    
    // Toggle new recording indicator visibility based on state.
    private func animateNewRecordingIndicator(toState state: MemberState) {
        // Only show new recording indicator when previewing.
        state == .previewing ? fadeInNewRecordingIndicator() : fadeOutNewRecordingIndicator()
    }
    
    // Upsert and show new recording indicator.
    private func fadeInNewRecordingIndicator() {
        // Upsert new recording indicator subview.
        let indicator = newRecordingIndicator ?? createNewRecordingIndicator()
        
        // Show the indicator.
        indicator.animator().alphaValue = 1
    }
    
    // Hide new recording indicator if it exists.
    private func fadeOutNewRecordingIndicator() {
        // Ensure new recording indicator subview exists.
        guard let indicator = newRecordingIndicator else {
            return
        }

        // Hide the indicator.
        indicator.animator().alphaValue = 0
    }
    
    // Upsert and fade-in the gaussian blur layer.
    private func fadeInBlurLayer() {
        animateAsGroup(
            values: [AnimationKey.blurRadius: Style.BlurLayer.blurRadius],
            duration: AnimationConfig.BlurLayer.duration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blurLayer ?? createBlurLayer()
        )
    }

    // Fade-out the gaussian blur layer and remove it.
    private func fadeOutBlurLayer() {
        // Ensure blur layer exists.
        guard let blur = blurLayer else {
            return
        }
        
        // Fade out blur layer.
        animateAsGroup(
            values: [AnimationKey.blurRadius: 0],
            duration: AnimationConfig.BlurLayer.duration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blur,
            completionHandler: {
                // Remove blur layer from image view layer after it's faded out.
                blur.removeFromSuperlayer()
            }
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
