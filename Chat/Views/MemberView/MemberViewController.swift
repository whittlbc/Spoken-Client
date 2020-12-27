//
//  MemberViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberViewController: NSViewController, ParticleViewDelegate {
    
    // Workspace member associated with this view.
    private var member: Member!
    
    // Initial member view frame -- provided from window.
    private var initialFrame: NSRect!
    
    // Avatar subview.
    private var avatarView: MemberAvatarView!
    
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
        // Create avatar view.
        createAvatarView()
        
        // Constrain avatar view.
        constrainAvatarView()
        
        // Render avatar view.
        avatarView.render()
    }
    
    // Create new avatar view subview.
    private func createAvatarView() {
        avatarView = MemberAvatarView()
        
        // Assign avatar URL string.
        avatarView.avatar = member.user.avatar
        
        // Make avatar view layer-based and allow overflow.
        avatarView.wantsLayer = true
        avatarView.layer?.masksToBounds = false

        // Add it as a subview.
        view.addSubview(avatarView)
    }
    
    // Add auto-layout constraints to avatar view.
    private func constrainAvatarView() {
        // Set up auto-layout for sizing/positioning.
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get default idle height for member window.
        let initialAvatarDiameter = MemberWindow.defaultSizeForState(.idle).height
        
        // Create height and width constraints for avatar view.
        let heightConstraint = avatarView.heightAnchor.constraint(equalToConstant: initialAvatarDiameter)
        let widthConstraint = avatarView.widthAnchor.constraint(equalToConstant: initialAvatarDiameter)
        
        // Get member view.
        let memberView = view as! MemberView
        
        // Create right constraint to be activated.
        memberView.avatarViewRightConstraint = avatarView.rightAnchor.constraint(equalTo: view.rightAnchor)
        
        // Create center-x constraint to be activated later.
        memberView.avatarViewCenterXConstraint = avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        
        // Identify constraints so you can query for them later.
        heightConstraint.identifier = MemberAvatarView.ConstraintKeys.height
        widthConstraint.identifier = MemberAvatarView.ConstraintKeys.width
        
        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set initial diameter to that of the "idle" member window height.
            heightConstraint,
            widthConstraint,

            // Align right sides.
            memberView.avatarViewRightConstraint,

            // Align horizontal axes.
            avatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
            relativeTo: avatarView
        )
    }
    
    // Update particle view frame to match that of member view and update corner radius to 50%.
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
}
