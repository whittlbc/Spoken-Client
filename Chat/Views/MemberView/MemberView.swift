//
//  MemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberView: NSView {

    // The member's state on screen at any given time -- should mirror that of MemberWindow.
    var state = MemberState.idle
    
    // Allow this view to be the first responder in the chain to key events.
    override var acceptsFirstResponder: Bool { true }
    
    // Allow the first click into this view to be "heard", event if the window itself isn't active at the time of click.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    
    // This view's size should always fill the entire contents of its window.
    override func layout() {
        super.layout()
        frame = bounds
    }

    // Add a tracking area that takes up the entirete of this view and listens for important mouse events.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Remove any old tracking areas.
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        // Always listen for mouse enter and exit events, regardless of window active status.
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        
        // Create latest tracking area.
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        // Add lastest tracking area.
        addTrackingArea(trackingArea)
    }
        
    // Assume latest state from parent window and animate self/subviews accordingly.
    func setState(_ newState: MemberState) {        
        state = newState
        
        switch state {
        // Animate to idle state.
        case .idle:
            animateToIdle()
        
        // Animate to previewing state.
        case .previewing:
            animateToPreviewing()
            
        // Animate to recording state.
        case .recording:
            animateToRecording()
        }
    }
    
    private func animateToIdle() {
        // Update member avatar.
        animateAvatarView()
    }
    
    private func animateToPreviewing() {
        // Update member avatar.
        animateAvatarView()
    }
    
    private func animateToRecording() {
        // Update member avatar.
        animateAvatarView()
    }
    
    private func animateAvatarView() {
        // Ensure member view has subviews.
        if subviews.count == 0 {
            logger.error("Can't animate member avatar view -- MemberView subviews is empty...")
            return
        }
        
        // Ensure member view has an avatar view.
        guard let avatarView = subviews[0] as? MemberAvatarView else {
            logger.error("Error extracting MemberAvatarView as first itsem in subviews: \(subviews[0])")
            return
        }

        // Ensure avatar view has both a height and width constraint.
        let heightConstraint = avatarView.constraints[0]
        let widthConstraint = avatarView.constraints[1]

        // Get desired avatar diameter -- use window height.
        let avatarDiameter = MemberWindow.defaultSizeForState(state).height

        // Animate avatar to new size.
        heightConstraint.animator().constant = avatarDiameter
        widthConstraint.animator().constant = avatarDiameter
    }
}
