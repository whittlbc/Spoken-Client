//
//  TeamMemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class TeamMemberView: NSView {
    
    static let width = 32
    
    static let height = 32
    
    var teamMember: NSDictionary

    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    required init(frame frameRect: NSRect, teamMember: NSDictionary) {
        self.teamMember = teamMember
        super.init(frame: frameRect)
        addSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        addAvatarView()
    }
    
    func addAvatarView() {
        let avatarDiameter = TeamMemberAvatarView.diameters["default"] as! Int
        let xOrigin = (TeamMemberView.width - avatarDiameter) / 2
        let yOrigin = (TeamMemberView.height - avatarDiameter) / 2
        let avatar = teamMember["avatar"] as! String
        let avatarImage = NSImage(byReferencing: NSURL(string: avatar)! as URL)

        let subview = TeamMemberAvatarView(
            frame: NSRect(x: xOrigin, y: yOrigin, width: avatarDiameter, height: avatarDiameter),
            image: avatarImage,
            shadowOffset: CGSize(width: -5, height: -6),
            shadowRadius: 4,
            shadowColor: CGColor.black,
            shadowOpacity: 0.9
        )

        addSubview(subview)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        print("DOWN")
    }
}
