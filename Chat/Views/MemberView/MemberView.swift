//
//  MemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberView: NSView {

    var state = MemberState.idle
    
    var isMouseInside = false
    
    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    
    override func layout() {
        super.layout()
        frame = bounds
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .cursorUpdate, .mouseMoved, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        addTrackingArea(trackingArea)
    }
        
    func setState(_ newState: MemberState) {        
        state = newState
        
        switch state {
        case .idle:
            animateToIdle()
        case .previewing:
            animateToPreviewing()
        case .recording:
            animateToRecording()
        }
    }
    
    private func animateToIdle() {
        let avatarView = subviews[0] as! MemberAvatarView
        let heightConstraint = avatarView.constraints[0]
        let widthConstraint = avatarView.constraints[1]

        heightConstraint.animator().constant = 32
        widthConstraint.animator().constant = 32
    }
    
    private func animateToPreviewing() {
        let avatarView = subviews[0] as! MemberAvatarView
        let heightConstraint = avatarView.constraints[0]
        let widthConstraint = avatarView.constraints[1]

        heightConstraint.animator().constant = 50
        widthConstraint.animator().constant = 50
    }

    private func animateToRecording() {
        let avatarView = subviews[0] as! MemberAvatarView
        let heightConstraint = avatarView.constraints[0]
        let widthConstraint = avatarView.constraints[1]

        heightConstraint.animator().constant = 50
        widthConstraint.animator().constant = 50
    }
}
