//
//  ChannelAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// View representing a channel's recipient avatar.
class ChannelAvatarView: NSView {
    
    // Auto-layout contraint identifiers.
    enum ConstraintKeys {
        static let height = "height"
        static let width = "width"
    }

    // Handle mouse up event.
    override func mouseUp(with event: NSEvent) {
        // Bubble up event to parent channel view.
        if let parent = getChannelView() {
            parent.onAvatarClick()
        }
    }
    
    // Get parent ChannelView.
    private func getChannelView() -> ChannelView? {
        superview as? ChannelView
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

    // Animate diameter of avatar for given state.
    func animateSize(toDiameter diameter: CGFloat) {
        // Ensure avatar view has both a height and width constraint.
        guard let heightConstraint = getHeightConstraint(), let widthConstraint = getWidthConstraint() else {
            logger.error("Both height and width constraints required to animate channel avatar view size...")
            return
        }
        
        // Animate avatar to new size.
        heightConstraint.animator().constant = diameter
        widthConstraint.animator().constant = diameter
    }
}
