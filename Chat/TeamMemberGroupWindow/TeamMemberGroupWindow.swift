//
//  TeamMemberGroupWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class TeamMemberGroupWindow: FloatingWindow {

    static let width:Int = 250
    
    static let teamMembers:NSArray = [
        TeamMemberWindow.ben,
        TeamMemberWindow.tyler,
        TeamMemberWindow.andrea,
    ]
    
    static func calculateHeight() -> Int {
        return TeamMemberGroupWindow.teamMembers.count * TeamMemberView.height
    }
    
    public func addChildWindows() {
        var i = 0

        for teamMember in TeamMemberGroupWindow.teamMembers.reversed() {
            addTeamMemberWindow(teamMember: teamMember as! NSDictionary, index: i)
            i += 1
        }
    }
    
    func addTeamMemberWindow(teamMember: NSDictionary, index: Int) {
        let teamMemberController = TeamMemberViewController()
        teamMemberController.teamMember = teamMember
        
        let teamMemberWindow = TeamMemberWindow(contentViewController: teamMemberController)

        teamMemberWindow.setFrameOrigin(NSPoint(
            x: CGFloat(Int(frame.origin.x) + SidebarWindow.width - TeamMemberWindow.offsetRight - TeamMemberView.width),
            y: CGFloat(Int(frame.origin.y) + (index * TeamMemberView.height))
        ))
        
        addChildWindow(teamMemberWindow, ordered: NSWindow.OrderingMode.above)
    }
}
