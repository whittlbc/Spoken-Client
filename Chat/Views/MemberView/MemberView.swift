//
//  MemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Primary content view of MemberWindow -- will always take up entire window size.
class MemberView: NSView {

    // View styling info.
    enum Style {
        
        // Opacity of view when disabled.
        static let disabledOpacity: CGFloat = 0.25
    }
    
    // The member's state on screen at any given time -- should mirror that of MemberWindow.
    var state = MemberState.idle

    // Whether member is able to be interacted with by the user.
    var isDisabled = false
    
    // Right auto-layout constraint of avatar view.
    var avatarViewRightConstraint: NSLayoutConstraint!
    
    // Center-X auto-layout constraint of avatar view.
    var avatarViewCenterXConstraint: NSLayoutConstraint!
        
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
    
    // Get parent MemberWindow.
    private func getMemberWindow() -> MemberWindow? {
        window as? MemberWindow
    }
    
    // Handle when avatar view is clicked on.
    func onAvatarClick() {
        // Ignore if view is disabled.
        if isDisabled {
            return
        }
        
        // Bubble up event to parent member window.
        if let parent = getMemberWindow() {
            parent.onAvatarClick()
        }
    }
        
    // Assume latest state from parent window and animate self/subviews accordingly.
    func setState(_ newState: MemberState, isDisabled disabled: Bool? = nil) {
        state = newState

        // Update disabled status if provided and different.
        if let newDisabledStatus = disabled, newDisabledStatus == !isDisabled {
            isDisabled = newDisabledStatus
            animateDisability()
        }
        
        // Update member avatar.
        animateAvatarView()
    }
    
    // Get child avatar view.
    func getAvatarView() -> MemberAvatarView? {
        // Ensure member view has subviews.
        if subviews.count == 0 {
            logger.error("Can't animate member avatar view -- MemberView subviews is empty...")
            return nil
        }
        
        // Get avatar view subview.
        guard let avatarView = firstSubview(ofType: MemberAvatarView.self) else {
            logger.error("Error extracting MemberAvatarView as a subview.")
            return nil
        }
        
        return avatarView
    }
    
    // Add recording style to subviews.
    func addRecordingStyle() {
        // Get avatar view.
        guard let avatarView = getAvatarView() else {
            return
        }
                
        // Flip avatar view x-alignment from right to center.
        avatarViewRightConstraint.isActive = false
        avatarViewCenterXConstraint.isActive = true
                        
        // Add recording style to avatar.
        avatarView.addRecordingStyle()
    }
    
    // Remove recording style to subviews.
    func removeRecordingStyle() {
        // Get avatar view.
        guard let avatarView = getAvatarView() else {
            return
        }

        // Flip avatar view x-alignment from right to center.
        avatarViewCenterXConstraint.isActive = false
        avatarViewRightConstraint.isActive = true
        
        // Add recording style to avatar.
        avatarView.removeRecordingStyle()
    }
        
    // Animate disabled state
    private func animateDisability() {
        animator().alphaValue = isDisabled ? Style.disabledOpacity : 1.0
    }
    
    // Animate avatar view to the current state.
    private func animateAvatarView() {
        // Get avatar view.
        guard let avatarView = getAvatarView() else {
            return
        }

        // Animate avatar view.
        avatarView.animateToState(state, isDisabled: isDisabled)
    }
}
