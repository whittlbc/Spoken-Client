//
//  TeamWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class TeamWindow: FloatingWindow {

    static let width:Int = 250
    
    static let teamMembers:NSArray = [
        TeamMemberWindow.ben,
        TeamMemberWindow.tyler,
        TeamMemberWindow.andrea,
    ]
    
    static func calculateHeight() -> Int {
        return TeamWindow.teamMembers.count * TeamMemberView.height
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        
        // *** TODO: Fetch current user's teams from back-end ***
        
        
        // --- TODO: All of this will be done after loading team from server. ---
        
        let teamHeight = TeamWindow.calculateHeight()

        setFrameOrigin(NSPoint(
            x: Screen.getWidth() - SidebarWindow.width,
            y: Screen.getHeight() - SidebarWindow.teamOffsetTop - teamHeight
        ))

        var teamFrame = frame
        teamFrame.size = NSSize(width: SidebarWindow.width, height: teamHeight)
        setFrame(teamFrame, display: true)

        // --------
        
        
        
        addChildWindows()
    }
    
    public func addChildWindows() {
        var i = 0

        for teamMember in TeamWindow.teamMembers.reversed() {
            addTeamMemberWindow(teamMember: teamMember as! NSDictionary, index: i)
            i += 1
        }
    }
    
    func addTeamMemberWindow(teamMember: NSDictionary, index: Int) {
        let teamMemberController = TeamMemberViewController()
        teamMemberController.teamMember = teamMember
        
        let teamMemberWindow = TeamMemberWindow(contentViewController: teamMemberController)
        teamMemberWindow.bind(.title, to: teamMemberController, withKeyPath: "title", options: nil)

        teamMemberWindow.setFrameOrigin(NSPoint(
            x: CGFloat(Int(frame.origin.x) + SidebarWindow.width - TeamMemberWindow.offsetRight - TeamMemberView.width),
            y: CGFloat(Int(frame.origin.y) + (index * TeamMemberView.height))
        ))
        
        addChildWindow(teamMemberWindow, ordered: NSWindow.OrderingMode.above)
        
        teamMemberWindow.makeFirstResponder(teamMemberController.view)
    }
}
