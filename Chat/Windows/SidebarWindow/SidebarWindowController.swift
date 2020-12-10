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
        
        // Initialize with new sidebar window.
        super.init(window: SidebarWindowController.newWindow())
        
        // Assign self as new sidebar window's delegate.
        self.window!.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func newWindow() -> SidebarWindow {
        // Create sidebar window.
        let window = SidebarWindow()

        // Right-align the window to the screen.
        window.setFrameOrigin(NSPoint(x: Screen.getWidth() - SidebarWindow.width, y: 0))

        // Set window frame size to take up the entire height of the screen.
        var frame = window.frame
        frame.size = NSSize(width: SidebarWindow.width, height: Screen.getHeight())
        window.setFrame(frame, display: true)

        return window
    }

    override func showWindow(_ sender: Any?) {
        // Show main sidebar window.
        super.showWindow(sender)
        
        // Add and show team window as a child window.
        addTeamChildWindow()
    }
    
    private func addTeamChildWindow() {
        window!.addChildWindow(TeamWindow(), ordered: NSWindow.OrderingMode.above)
    }
}
