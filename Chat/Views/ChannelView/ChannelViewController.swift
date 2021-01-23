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
    
    // Different supported horizontal alignments of avatar inside of channel view.
    enum AvatarHorizontalAlignment {
        case right
        case center
    }
    
    // Workspace channel associated with this view.
    private var channel: Channel!
    
    // Controller for avatar view subview.
    private var avatarViewController: ChannelAvatarViewController!
    
    // Right auto-layout constraint of avatar view.
    private var avatarViewRightConstraint: NSLayoutConstraint!

    // Center-X auto-layout constraint of avatar view.
    private var avatarViewCenterXConstraint: NSLayoutConstraint!

    // Channel particle view for audio animation.
    private var particleView: ChannelParticleView!

    // Proper init to call when creating this class.
    convenience init(channel: Channel) {
        self.init()
        self.channel = channel
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
        view = ChannelView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add avatar view as subview.
        addAvatarView()
        
        // Create particle view for voice audio animation.
        createParticleView()
    }
    
    // Handle changes in channel disability.
    func isDisabledChanged(to isDisabled: Bool) {
        // Change alpha value of view based on isDisabled status.
        animateAlpha(to: isDisabled ? ChannelView.Style.disabledOpacity : 1.0)
        
        // Pass this change down to avatar view controller.
        avatarViewController.isDisabledChanged(to: isDisabled)
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
        let initialAvatarDiameter = ChannelWindow.Style.idleSize.height
        
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
        
        // Pipe mic input into particle view.
        particleView.tapMic()
        
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
        // TODO: handle metal unavailable here
    }
    
    // Handle each frame of particle view (should be running at 60fps).
    func particleViewDidUpdate() {
        particleView.resetGravityWells()
        particleView.handleParticleStep()
    }
    
    // Animate alpha value of channel view.
    private func animateAlpha(to value: CGFloat) {
        view.animator().alphaValue = value
    }
    
    // Update avatar view horizontal alignment.
    private func alignAvatar(to alignment: AvatarHorizontalAlignment) {
        switch alignment {
        case .right:
            avatarViewRightConstraint.isActive = true
            avatarViewCenterXConstraint.isActive = false
        case .center:
            avatarViewRightConstraint.isActive = false
            avatarViewCenterXConstraint.isActive = true
        }
    }
    
    // Reset contents back to initial idle state.
    private func resetToIdle() {
        // Nothing should have changed if using video.
        if UserSettings.Video.useCamera {
            return
        }

        // Flip avatar view x-alignment from center back to right.
        alignAvatar(to: .right)
        
        // Remove particle view as a subview.
        removeParticleView()
        
        // Reset particle view.
        particleView.reset()
    }
    
    // Rendered with recording:started state.
    private func renderStartedRecording() {
        // Don't change anything if using video for recording.
        if UserSettings.Video.useCamera {
            return
        }
        
        // Flip avatar view x-alignment from right to center.
        alignAvatar(to: .center)
        
        // Add particle view as a subview.
        addParticleView()
    }
    
    // Rendered with recording:cancelling state.
    private func renderCancellingRecording() {
        resetToIdle()
    }
    
    // Rendered with recording:sending state.
    private func renderSendingRecording() {
        // Particle view is only used if camera is not.
        if UserSettings.Video.useCamera {
            return
        }

        // Explode the particle view.
        particleView.explode()
    }
    
    // Rendered with recording:finished state.
    private func renderFinishedRecording() {
        resetToIdle()
    }
    
    // Render recording-specific view updates.
    private func renderRecording(status recordingStatus: RecordingStatus) {
        switch recordingStatus {
        case .started:
            renderStartedRecording()
        case .cancelling:
            renderCancellingRecording()
        case .sending:
            renderSendingRecording()
        case .finished:
            renderFinishedRecording()
        default:
            break
        }
    }
    
    // Render state-specific view updates.
    private func renderState(_ state: ChannelState) {
        switch state {
        case .recording(let recordingStatus):
            renderRecording(status: recordingStatus)
        default:
            break
        }
    }

    // Render avatar view controller with given channel state.
    private func renderAvatar(_ state: ChannelState) {
        avatarViewController.render(state)
    }
    
    // Render window to size/position.
    func render(_ spec: ChannelRenderSpec, _ state: ChannelState) {
        // Render based on state.
        renderState(state)
        
        // Render avatar view controller.
        renderAvatar(state)
    }
}
