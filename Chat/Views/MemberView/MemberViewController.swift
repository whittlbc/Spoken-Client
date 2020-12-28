//
//  MemberViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Controller for MemberView to manage all of its subviews and their interactions.
class MemberViewController: NSViewController, ParticleViewDelegate {
    
    // View styling info.
    enum Style {
        
        // MemberView styling info.
        enum MemberView {
            // Opacity of view when disabled.
            static let disabledOpacity: CGFloat = 0.25
        }
    }
    
    // Workspace member associated with this view.
    private var member: Member!
    
    // Initial member view frame -- provided from window.
    private var initialFrame: NSRect!

    // Controller for avatar view subview.
    private var avatarViewController: MemberAvatarViewController!
    
    // Right auto-layout constraint of avatar view.
    private var avatarViewRightConstraint: NSLayoutConstraint!

    // Center-X auto-layout constraint of avatar view.
    private var avatarViewCenterXConstraint: NSLayoutConstraint!

    // Member particle view for audio animation.
    private var particleView: MemberParticleView!
        
    // Proper initializer to use when rendering member.
    convenience init(member: Member, initialFrame: NSRect) {
        self.init()
        self.member = member
        self.initialFrame = initialFrame
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
        view = MemberView(frame: initialFrame)
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
        avatarViewController = MemberAvatarViewController(member: member)
        
        // Add avatar view as a subview.
        view.addSubview(avatarViewController.view)
        
        // Constrain avatar view with auto-layout.
        constrainAvatarView()
    }
    
    // Add auto-layout constraints to avatar view.
    private func constrainAvatarView() {
        // Set up auto-layout for sizing/positioning.
        avatarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Get default idle height for member window.
        let initialAvatarDiameter = MemberWindow.defaultSizeForState(.idle).height
        
        // Create height and width constraints for avatar view.
        let heightConstraint = avatarViewController.view.heightAnchor.constraint(equalToConstant: initialAvatarDiameter)
        let widthConstraint = avatarViewController.view.widthAnchor.constraint(equalToConstant: initialAvatarDiameter)
        
        // Create right constraint to be activated.
        avatarViewRightConstraint = avatarViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        
        // Create center-x constraint to be activated later.
        avatarViewCenterXConstraint = avatarViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        // Identify constraints so you can query for them later.
        heightConstraint.identifier = MemberAvatarView.ConstraintKeys.height
        widthConstraint.identifier = MemberAvatarView.ConstraintKeys.width
        
        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set initial diameter to that of the "idle" member window height.
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
        particleView = MemberParticleView()
        particleView.particleViewDelegate = self
    }
    
    // Add particle view as subview.
    func addParticleView() {
        // Update frame size of particle view to match member view.
        updateParticleViewSize()
        
        // Add particle view below avatar view.
        view.addSubview(
            particleView,
            positioned: NSWindow.OrderingMode.below,
            relativeTo: avatarViewController.view
        )
    }
    
    // Update particle view frame to match that of member view and update corner radius to 50%.
    func updateParticleViewSize() {
        particleView.frame = view.frame
        particleView.layer?.cornerRadius = view.frame.size.height / 2
    }
    
    // Remove particle view as a subview.
    func removeParticleView() {
        if view.firstSubview(ofType: ParticleView.self) == nil {
            return
        }
        
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
        view.animator().alphaValue = isDisabled ? Style.MemberView.disabledOpacity : 1.0
    }
    
    private func renderRecordingHasStarted() {
        // Flip avatar view x-alignment from right to center.
        avatarViewRightConstraint.isActive = false
        avatarViewCenterXConstraint.isActive = true
        
        // Add particle view as a subview.
        addParticleView()
    }
    
    private func renderRecordingNotStarted() {
        // Flip avatar view x-alignment from right to center.
        avatarViewCenterXConstraint.isActive = false
        avatarViewRightConstraint.isActive = true
        
        // Remove particle view as a subview (if it is one).
        removeParticleView()
    }
    
    // Render state-specific view updates.
    private func renderStateChanges(state: MemberState) {
        switch state {
        case .recording(let hasStarted):
            hasStarted ? renderRecordingHasStarted() : renderRecordingNotStarted()
        default:
            break
        }
    }

    private func renderAvatarView(state: MemberState, isDisabled: Bool? = nil) {
        avatarViewController.render(state: state, isDisabled: isDisabled)
    }
    
    // Render view and subviews with updated state and props.
    func render(state: MemberState, isDisabled: Bool? = nil) {
        // Animate disabled status if provided.
        if let disabled = isDisabled {
            animateDisability(disabled)
        }
        
        renderStateChanges(state: state)
        
        renderAvatarView(state: state, isDisabled: isDisabled)
    }
}
