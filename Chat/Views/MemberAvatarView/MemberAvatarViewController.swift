//
//  MemberAvatarViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Controller for MemberAvatarView to manage all of its subviews and their interactions.
class MemberAvatarViewController: NSViewController {
    
    // Workspace member associated with this view.
    private var member: Member!

    // Container view of avatar.
    private var containerView: RoundShadowView!
    
    // View with image content.
    private var imageView: RoundView!
    
    // New recording indicator icon.
    private var newRecordingIndicator: RoundShadowView?

    // Blur layer to fade-in when member is disabled.
    private var blurLayer: CALayer?
    
    // Spinner view around avatar to show when sending a recording.
    private var spinnerView: ChasingTailSpinnerView?
    
    // Self-drawn checkmark view to show when a recording is sent.
    private var checkmarkView: SelfDrawnCheckmarkView?

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
                    radius: 2.5,
                    opacity: 0.5
                )
                
                // Raised shadow style.
                static let raised = Shadow(
                    offset: CGSize(width: 1.0, height: -2),
                    radius: 4.5,
                    opacity: 0.5
                )
                
                // Get shadow style config for member state.
                static func getShadow(forState state: MemberState) -> Shadow {
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
        
        // Container view animation config.
        enum ContainerView {
            static let duration = WorkspaceWindow.AnimationConfig.MemberWindows.duration
            static let timingFunctionName = WorkspaceWindow.AnimationConfig.MemberWindows.timingFunctionName
        }
        
        // Image blur layer animation config.
        enum BlurLayer {
            
            // Duration used when applying disabled effect.
            static let disabledDuration = WorkspaceWindow.AnimationConfig.MemberWindows.duration
            
            // Timing function used when fading in/out blur layer.
            static let timingFunctionName = WorkspaceWindow.AnimationConfig.MemberWindows.timingFunctionName
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
    
    // Proper initializer to use when rendering member.
    convenience init(member: Member) {
        self.init(nibName: nil, bundle: nil)
        self.member = member
    }
    
    // Override delegated init.
    private override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use MemberView as primary view for this controller.
    override func loadView() {
        view = MemberAvatarView(avatar: member.user.avatar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewLayer()
        
        addContainerView()

        addImageView()
    }
    
    private func getAvatarView() -> MemberAvatarView {
        view as! MemberAvatarView
    }
    
    private func setupViewLayer() {
        // Make avatar view layer-based and allow overflow.
        view.wantsLayer = true
        view.layer?.masksToBounds = false
    }

    // Render container view.
    private func addContainerView() {
        // Create container view.
        createContainerView()
        
        // Constrain container view.
        constrainContainerView()
    }
    
    // Render image view.
    private func addImageView() {
        // Create image view.
        createImageView()
        
        // Constrain image view.
        constrainImageView()
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
                
        // Add container view as subview..
        view.addSubview(containerView)
    }
    
    // Set up container view auto-layout.
    private func constrainContainerView() {
        // Set up auto-layout for sizing/positioning.
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of container.
            containerView.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: Style.ContainerView.PositionStyle.relativeHeight
            ),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Center-align axes.
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
        let image = NSImage(byReferencing: URL(string: getAvatarView().avatar)!)
                
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
        view.addSubview(
            indicator,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: containerView
        )
        
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
                equalTo: view.heightAnchor,
                multiplier: Style.NewRecordingIndicator.PositionStyle.relativeHeight
            ),
            
            // Keep indicator height and width the same.
            indicator.widthAnchor.constraint(equalTo: indicator.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            indicator.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: Style.NewRecordingIndicator.PositionStyle.edgeOffset
            ),
            
            // Align bottom sides (but shift it up the specified amount).
            indicator.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
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
        blur.backgroundColor = CGColor.clear
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
        
    // Create spinner view to spin around avatar during sending of recording.
    private func createSpinnerView() -> ChasingTailSpinnerView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        // Create spinner frame in center of image view frame.
        let spinnerFrame = NSRect(
            x: (imageSize.width - Style.SpinnerView.diameter) / 2,
            y: (imageSize.height - Style.SpinnerView.diameter) / 2,
            width: Style.SpinnerView.diameter,
            height: Style.SpinnerView.diameter
        )
        
        // Create new chasing tail spinner.
        let spinner = ChasingTailSpinnerView(
            frame: spinnerFrame,
            color: Style.SpinnerView.color
        )
        
        // Add spinner as subview of container view.
        containerView.addSubview(
            spinner,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return spinner
    }
    
    // Create self-drawing checkmark view to show when recording is successfully sent.
    private func createCheckmarkView() -> SelfDrawnCheckmarkView {
        // Get size of image view frame.
        let imageSize = imageView.frame.size
        
        // Create checkmark frame.
        let checkmarkFrame = NSRect(
            x: (imageSize.width - Style.CheckmarkView.length) / 2,
            y: (imageSize.height - Style.CheckmarkView.length) / 2,
            width: Style.CheckmarkView.length,
            height: Style.CheckmarkView.length
        )
        
        // Create new self-drawn checkmark view.
        let checkmark = SelfDrawnCheckmarkView(
            frame: checkmarkFrame,
            color: Style.CheckmarkView.color
        )
        
        // Add checkmark as subview of container view.
        containerView.addSubview(
            checkmark,
            positioned: NSWindow.OrderingMode.above,
            relativeTo: imageView
        )
        
        return checkmark
    }
    
    // Determine whether a state change should cause a size change animation.
    private func stateShouldCauseAvatarSizeChange(_ state: MemberState) -> Bool {
        switch state {
        case .idle,
             .previewing:
            return true
        case .recording(let recordingStatus):
            return recordingStatus == .starting
        }
    }
    
    private func animateAvatarViewSize(toState state: MemberState) {
        getAvatarView().animateSize(toDiameter: MemberWindow.defaultSizeForState(state).height)
    }
    
    // Toggle the amount of drop shadow for container view based on state.
    private func animateContainerViewShadow(toState state: MemberState) {
        containerView.updateShadow(
            toConfig: Style.ContainerView.ShadowStyle.getShadow(forState: state),
            animate: true,
            duration: AnimationConfig.ContainerView.duration,
            timingFunctionName: AnimationConfig.ContainerView.timingFunctionName
        )
    }
    
    // Toggle blur layer based on disabled status of member.
    private func animateImageViewBlur(showBlur: Bool, blurRadius: Double, duration: CFTimeInterval) {
        showBlur ? fadeInBlurLayer(blurRadius: blurRadius, duration: duration) : fadeOutBlurLayer(duration: duration)
    }
    
    // Toggle new recording indicator visibility based on state.
    private func animateNewRecordingIndicatorVisibility(toState state: MemberState) {
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
    private func fadeInBlurLayer(blurRadius: Double, duration: CFTimeInterval, alpha: CGFloat? = 0) {
        view.animateAsGroup(
            values: [
                NSView.AnimationKey.blurRadius: blurRadius,
                NSView.AnimationKey.backgroundColor: Color.fromRGBA(0, 0, 0, alpha!).cgColor
            ],
            duration: duration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blurLayer ?? createBlurLayer()
        )
    }

    // Fade-out the gaussian blur layer and remove it.
    private func fadeOutBlurLayer(duration: CFTimeInterval) {
        // Ensure blur layer exists.
        guard let blur = blurLayer else {
            return
        }
        
        // Fade out blur layer.
        view.animateAsGroup(
            values: [
                NSView.AnimationKey.blurRadius: 0,
                NSView.AnimationKey.backgroundColor: CGColor.clear
            ],
            duration: duration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            onLayer: blur,
            completionHandler: { [weak self] in
                // Remove blur layer from image view layer after it's faded out.
                self?.blurLayer?.removeFromSuperlayer()
                self?.blurLayer = nil
            }
        )
    }
    
    private func fadeInSpinnerView() {
        // Upsert spinner view.
        spinnerView = spinnerView ?? createSpinnerView()
        
        // Hide spinner layer with opacity.
        spinnerView!.layer?.opacity = 0.0
        
        // Start spinner.
        spinnerView!.spin()

        // Fade in opacity.
        spinnerView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 1.0],
            duration: AnimationConfig.SpinnerView.enterDuration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName
        )
    }

    // Fade out spinner view and remove it when animation finishes.
    private func fadeOutSpinnerView() {
        if spinnerView == nil {
            return
        }
        
        spinnerView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 0.0],
            duration: AnimationConfig.CheckmarkView.enterDuration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            completionHandler: { [weak self] in
                self?.spinnerView?.removeFromSuperview()
                self?.spinnerView = nil
            }
        )
    }
    
    private func addCheckmarkView() {
        // Upsert checkmark view.
        checkmarkView = checkmarkView ?? createCheckmarkView()
        
        // Draw the checkmark.
        checkmarkView!.drawStroke()
    }

    // Fade out spinner view and remove it when animation finishes.
    private func fadeOutCheckmarkView() {
        if checkmarkView == nil {
            return
        }
        
        checkmarkView!.animateAsGroup(
            values: [NSView.AnimationKey.opacity: 0.0],
            duration: AnimationConfig.CheckmarkView.exitDuration,
            timingFunctionName: AnimationConfig.BlurLayer.timingFunctionName,
            completionHandler: { [weak self] in
                self?.checkmarkView?.removeFromSuperview()
                self?.checkmarkView = nil
            }
        )
    }
    
    private func renderAvatarView(state: MemberState) {
        if stateShouldCauseAvatarSizeChange(state) {
            animateAvatarViewSize(toState: state)
        }
    }
    
    private func renderContainerView(state: MemberState) {
        animateContainerViewShadow(toState: state)
    }
    
    private func renderBlurLayer(state: MemberState, isDisabled: Bool? = nil) {
        if state === .recording(.sending) {
            // Fade in blur layer to avatar image.
            fadeInBlurLayer(
                blurRadius: Style.BlurLayer.spinBlurRadius,
                duration: AnimationConfig.SpinnerView.enterDuration,
                alpha: Style.BlurLayer.spinAlpha
            )
            
            return
        }
        
        if state === .recording(.sent) {
            return
        }
        
        if state === .recording(.cancelling) {
            fadeOutBlurLayer(
                duration: AnimationConfig.CheckmarkView.exitDuration
            )
            
            return
        }
        
        if let disabled = isDisabled {
            animateImageViewBlur(
                showBlur: disabled,
                blurRadius: Style.BlurLayer.disabledBlurRadius,
                duration: AnimationConfig.BlurLayer.disabledDuration
            )
        }
    }
    
    private func renderNewRecordingIndicator(state: MemberState) {
        animateNewRecordingIndicatorVisibility(toState: state)
    }
    
    private func renderSpinnerView(state: MemberState) {
        // If sending recording, fade in the spinner view.
        if state === .recording(.sending) {
            fadeInSpinnerView()
            return
        }
        
        // If recording was sent, fade out the spinner view.
        if state === .recording(.sent) {
            fadeOutSpinnerView()
        }
    }
    
    private func renderCheckmarkView(state: MemberState) {
        // If recording was sent, add the checkmark view.
        if state === .recording(.sent) {
            addCheckmarkView()
            return
        }
        
        // If recording is complete, fade out the checkmark view.
        if state === .recording(.cancelling) {
            fadeOutCheckmarkView()
        }
    }

    // Render view and subviews with updated state and props.
    func render(state: MemberState, isDisabled: Bool? = nil) {
        
        renderAvatarView(state: state)
        
        renderContainerView(state: state)
    
        renderBlurLayer(state: state, isDisabled: isDisabled)
        
        renderNewRecordingIndicator(state: state)
        
        renderSpinnerView(state: state)
        
        renderCheckmarkView(state: state)
    }
}
