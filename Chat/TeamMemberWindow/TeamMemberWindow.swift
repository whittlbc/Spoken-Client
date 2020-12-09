//
//  TeamMemberWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class TeamMemberWindow: FloatingWindow {
 
    static let offsetRight = 6

    static let ben:NSDictionary = [
        "avatar" : "https://dacxe0nzqx93t.cloudfront.net/team/ben-whittle/avatar.jpg",
    ]

    static let tyler:NSDictionary = [
        "avatar" : "https://dacxe0nzqx93t.cloudfront.net/team/tyler-whittle/tyler.jpg",
    ]

    static let andrea:NSDictionary = [
        "avatar" : "https://dacxe0nzqx93t.cloudfront.net/team/andrea-salazar/color-avatar.jpg",
    ]
    
    private var isMouseInside:Bool = false
    
    override func mouseEntered(with event: NSEvent) {
        if (isMouseInside) {
            return
        }
        
        isMouseInside = true
        
        makeKeyAndOrderFront(self)
        
        backgroundColor = NSColor.white
        
        var newFrame = frame
        newFrame.origin.x -= 20
        newFrame.size.width += 20
        
        setFrame(newFrame, display: true)
    }

    override func mouseExited(with event: NSEvent) {
        if (!isMouseInside) {
            return
        }
        
        isMouseInside = false
        backgroundColor = NSColor.clear
        
        var newFrame = frame
        newFrame.origin.x += 20
        newFrame.size.width -= 20
        
        setFrame(newFrame, display: true)
    }
}
