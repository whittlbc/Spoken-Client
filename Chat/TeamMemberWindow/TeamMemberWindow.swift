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
    
    override func mouseEntered(with event: NSEvent) {
        makeKeyAndOrderFront(self)
    }

    override func mouseExited(with event: NSEvent) {
    }
}
