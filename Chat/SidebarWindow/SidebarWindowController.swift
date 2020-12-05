//
//  SidebarWindowController.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import AppKit

class SidebarWindowController: NSWindowController, NSWindowDelegate {

    convenience init() {
        self.init(window: nil)
    }
    
    private override init(window: NSWindow?) {
        precondition(window == nil, "call init() with no window")
                        
        let window = SidebarWindow()

        window.setFrameOrigin(NSPoint(x: Screen.getWidth() - SidebarWindow.width, y: 0))

        var frame = window.frame
        frame.size = NSSize(width: SidebarWindow.width, height: Screen.getHeight())
        window.setFrame(frame, display: true)

        super.init(window: window)
        
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addChildWindows() {
        // Add active team member group window
        addActiveTeamMembersGroupWindow()
    }
    
    func addActiveTeamMembersGroupWindow() {
        let win = window!
        let teamMembersGroupWindow = TeamMemberGroupWindow()
        let teamMembersGroupHeight = TeamMemberGroupWindow.calculateHeight()

        teamMembersGroupWindow.setFrameOrigin(NSPoint(
            x: Int(win.frame.origin.x),
            y: Screen.getHeight() - SidebarWindow.activeTeamMembersGroupOffsetTop - teamMembersGroupHeight
        ))

        var teamMembersGroupFrame = teamMembersGroupWindow.frame
        teamMembersGroupFrame.size = NSSize(width: Int(win.frame.size.width), height: teamMembersGroupHeight)
        teamMembersGroupWindow.setFrame(teamMembersGroupFrame, display: true)
        
        win.addChildWindow(teamMembersGroupWindow, ordered: NSWindow.OrderingMode.above)
        
        teamMembersGroupWindow.addChildWindows()
    }
}
