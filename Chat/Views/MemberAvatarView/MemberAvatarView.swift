//
//  MemberAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// View representing a workspace member's avatar.
class MemberAvatarView: NSView {
    
    // Auto-layout contraint identifiers.
    enum ConstraintKeys {
        static let height = "height"
        static let width = "width"
    }
    
    // URL string to avatar.
    var avatar: String!
    
    convenience init(avatar: String) {
        self.init(frame: NSRect())
        self.avatar = avatar
    }
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Handle mouse up event.
    override func mouseUp(with event: NSEvent) {
        // Bubble up event to parent member view.
        if let parent = getMemberView() {
            parent.onAvatarClick()
        }
    }
    
    // Get parent MemberView.
    private func getMemberView() -> MemberView? {
        superview as? MemberView
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
            logger.error("Both height and width constraints required to animate member avatar view size...")
            return
        }

        // Ensure size isn't already this diameter.
        if heightConstraint.constant == diameter && widthConstraint.constant == diameter {
            return
        }
        
        // Animate avatar to new size.
        heightConstraint.animator().constant = diameter
        widthConstraint.animator().constant = diameter
    }
}
