//
//  MemberViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberViewController: NSViewController, ParticleLabDelegate {

    // Workspace member associated with this view.
    private var member = Member()
    
    // Initial member view frame -- provided from window.
    private var initialFrame = NSRect()
    
    // Avatar subview.
    private var avatarView = MemberAvatarView()
    
    private var particleLab: ParticleLab!
        
    private var steps: Int = 0
    
    private var prepSteps: Int = 0
    
    private var particlePrepTimer: Timer?

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
        
        particleLab = ParticleLab(
            width: UInt(120),
            height: UInt(120),
            numParticles: ParticleCount.TwentyFourtyEight
        )

        particleLab.particleLabDelegate = self
        particleLab.dragFactor = 0.95
        particleLab.clearOnStep = true
        particleLab.respawnOutOfBoundsParticles = false
        particleLab.resetParticles(edgesOnly: false)
        
        startTimer()
    }
    
    // Start timer used to check whether mouse is still inside the previewing window.
    func startTimer() {
        if particlePrepTimer != nil {
            return
        }
        
        // Create timer that repeats call to self.ensureStillPreviewing every 150ms.
        particlePrepTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(0.0166),
            target: self,
            selector: #selector(prepTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    // Invalidate previewing timer and reset to nil if it exists.
    func cancelTimer() {
        if particlePrepTimer == nil {
            return
        }
        
        particlePrepTimer!.invalidate()
        particlePrepTimer = nil
    }
    
    @objc func prepTimer() {
        var j = 0
        
        if prepSteps % 30 == 0 {
            particleLab.setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: prepSteps % 60 == 0 ? 0.4 : 0.6,
                mass: 40,
                spin: 25
            )
            
            j = 1
        }
        
        for index in j..<4 {
            particleLab.setGravityWellProperties(
                gravityWellIndex: index,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 0,
                spin: 0
            )
        }
        
        particleLab.stepThrough()

        prepSteps += 1
        
        if prepSteps == 180 {
            cancelTimer()
        }
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
    
    func addParticleLab() {
        particleLab.frame = view.frame
        particleLab.layer?.cornerRadius = view.frame.size.height / 2
                
        view.addSubview(particleLab, positioned: NSWindow.OrderingMode.below, relativeTo: avatarView)
    }
    
    func removeParticleLab() {
        particleLab.removeFromSuperview()
    }
    
    func particleLabMetalUnavailable() {
        // handle metal unavailable here
    }
    
    func particleLabDidUpdate(status: String) {
        particleLab.resetGravityWells()
        handleParticleStep()
        steps += 1
    }
        
    func handleParticleStep() {
        var i = 0

        if steps % 80 == 0 {
            particleLab.setGravityWellProperties(
                gravityWellIndex: 0,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 40,
                spin: 25
            )

            i = 1
        }

        for index in i..<4 {
            particleLab.setGravityWellProperties(
                gravityWellIndex: index,
                normalisedPositionX: 0.5,
                normalisedPositionY: 0.5,
                mass: 0,
                spin: 0
            )
        }
    
    }
}
