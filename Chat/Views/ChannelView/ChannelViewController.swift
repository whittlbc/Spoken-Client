//
//  ChannelViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Controller for ChannelView to manage all of its subviews and their interactions.
class ChannelViewController: NSViewController, ParticleViewDelegate {
    
    // View styling info.
    enum Style {
        
        // ChannelView styling info.
        enum ChannelView {
            // Opacity of view when disabled.
            static let disabledOpacity: CGFloat = 0.25
        }
    }
    
    // Workspace channel associated with this view.
    private var channel: Channel!
    
    // Initial channel view frame -- provided from window.
    private var initialFrame: NSRect!

    // Controller for avatar view subview.
    private var avatarViewController: ChannelAvatarViewController!
    
    // Right auto-layout constraint of avatar view.
    private var avatarViewRightConstraint: NSLayoutConstraint!

    // Center-X auto-layout constraint of avatar view.
    private var avatarViewCenterXConstraint: NSLayoutConstraint!

    // Channel particle view for audio animation.
    private var particleView: ChannelParticleView!
        
    // Proper initializer to use when rendering channel.
    convenience init(channel: Channel, initialFrame: NSRect) {
        self.init()
        self.channel = channel
        self.initialFrame = initialFrame
    }
    
    // Override delegated init.
    private override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Use ChannelView as primary view for this controller.
    override func loadView() {
        view = ChannelView(frame: initialFrame)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add avatar view as subview.
        addAvatarView()
        
        // Create particle view for voice audio animation.
        createParticleView()
    }
    
    private func addAvatarView() {
        // Create avatar view controller.
        avatarViewController = ChannelAvatarViewController(channel: channel)
        
        // Add avatar view as a subview.
        view.addSubview(avatarViewController.view)
        
        // Constrain avatar view with auto-layout.
        constrainAvatarView()
    }
    
    // Add auto-layout constraints to avatar view.
    private func constrainAvatarView() {
        // Set up auto-layout for sizing/positioning.
        avatarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Get default idle height for channel window.
        let initialAvatarDiameter = ChannelWindow.defaultSizeForState(.idle).height
        
        // Create height and width constraints for avatar view.
        let heightConstraint = avatarViewController.view.heightAnchor.constraint(equalToConstant: initialAvatarDiameter)
        let widthConstraint = avatarViewController.view.widthAnchor.constraint(equalToConstant: initialAvatarDiameter)
        
        // Create right constraint to be activated.
        avatarViewRightConstraint = avatarViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        
        // Create center-x constraint to be activated later.
        avatarViewCenterXConstraint = avatarViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        // Identify constraints so you can query for them later.
        heightConstraint.identifier = ChannelAvatarView.ConstraintKeys.height
        widthConstraint.identifier = ChannelAvatarView.ConstraintKeys.width
        
        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set initial diameter to that of the "idle" channel window height.
            heightConstraint,
            widthConstraint,

            // Align right sides.
            avatarViewRightConstraint,

            // Align horizontal axes.
            avatarViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    // Create particle view and set self as delegate.
    func createParticleView() {
        particleView = ChannelParticleView()
        particleView.particleViewDelegate = self
    }
    
    // Add particle view as subview.
    func addParticleView() {
        // Update frame size of particle view to match channel view.
        updateParticleViewSize()
        
        // Add particle view below avatar view.
        view.addSubview(
            particleView,
            positioned: NSWindow.OrderingMode.below,
            relativeTo: avatarViewController.view
        )
    }
    
    // Update particle view frame to match that of channel view and update corner radius to 50%.
    func updateParticleViewSize() {
        particleView.frame = view.frame
        particleView.layer?.cornerRadius = view.frame.size.height / 2
    }
    
    // Remove particle view as a subview.
    func removeParticleView() {
        particleView.removeFromSuperview()
    }
    
    func particleViewMetalUnavailable() {
        // handle metal unavailable here
    }
    
    // Handle each frame of particle view (should be running at 60fps).
    func particleViewDidUpdate() {
        particleView.resetGravityWells()
        particleView.handleParticleStep()
    }
    
    // Animate disabled state.
    private func animateDisability(_ isDisabled: Bool) {
        view.animator().alphaValue = isDisabled ? Style.ChannelView.disabledOpacity : 1.0
    }
    
    private func renderStartedRecording() {
        // Flip avatar view x-alignment from right to center.
        avatarViewRightConstraint.isActive = false
        avatarViewCenterXConstraint.isActive = true
        
        // Add particle view as a subview.
        addParticleView()
    }
    
    private func renderCancellingRecording() {
        // Flip avatar view x-alignment from right to center.
        avatarViewCenterXConstraint.isActive = false
        avatarViewRightConstraint.isActive = true
        
        // Remove particle view as a subview.
        removeParticleView()
        
        // Reset particle view.
        particleView.reset()
    }
    
    private func renderSendingRecording() {
        // Explode the particle view.
        particleView.explode()
    }
    
    // Render recording-specific view updates.
    private func renderRecordingStateChange(recordingStatus: RecordingStatus) {
        switch recordingStatus {
        case .started:
            renderStartedRecording()
        case .cancelling:
            renderCancellingRecording()
        case .sending:
            renderSendingRecording()
        default:
            break
        }
    }
    
    // Render state-specific view updates.
    private func renderStateChanges(state: ChannelState) {
        switch state {
        case .recording(let recordingStatus):
            renderRecordingStateChange(recordingStatus: recordingStatus)
        default:
            break
        }
    }

    private func renderAvatarView(state: ChannelState, isDisabled: Bool? = nil) {
        avatarViewController.render(state: state, isDisabled: isDisabled)
    }
    
    // Render view and subviews with updated state and props.
    func render(state: ChannelState, isDisabled: Bool? = nil) {
        // Animate disabled status if provided.
        if let disabled = isDisabled {
            animateDisability(disabled)
        }
        
        renderStateChanges(state: state)
        
        renderAvatarView(state: state, isDisabled: isDisabled)
    }
}
