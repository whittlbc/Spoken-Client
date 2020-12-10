//
//  WorkspaceWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class WorkspaceWindow: FloatingWindow {
    
    // Let size and origin of window be equivalent to that of the Sidebar.
    static let size = SidebarWindow.size
    static let origin = SidebarWindow.origin

    // Override delegated init, size/position window on screen, and fetch workspaces.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        // Position and size window on screen.
        repositionWindow(to: SidebarWindow.origin)
        resizeWindow(to: SidebarWindow.size)
        
        // Load the current workspace.
        loadWorkspace()
    }
    
    // Load the current workspace for this user.
    func loadWorkspace() {
        // Get current workspace.
        // Fetch current workspace members.
        // Render members on screen as individual windows.
    }
}

