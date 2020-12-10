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
    
    // Current workspace.
    var workspace = Workspace()

    // Override delegated init, size/position window on screen, and fetch workspaces.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        // Position and size window on screen.
        repositionWindow(to: SidebarWindow.origin)
        resizeWindow(to: SidebarWindow.size)
        
        // Load the current workspace.
        loadCurrentWorkspace()
    }
    
    // Load the current workspace for this user.
    func loadCurrentWorkspace() {
        // Get the current workspace or show the create new workspace window if user doesn't have any.
        guard let currentWorkspace = getCurrentWorkspace() else {
            showCreateNewWorkspace()
            return
        }
        
        // Assign workspace as current workspace.
        workspace = currentWorkspace
        
        // Fetch all members in the current workspace.
        // workspace.fetchMembers()
        
        // Render each member on screen as a separate window.
        // workspace.members.forEach...
    }
    
    func getCurrentWorkspace() -> Workspace? {
        // If current workspace exists already, return it.
        if let ws = Workspace.current {
            return ws
        }

        // Fetch all workspaces for current user.
        // User.current!.fetchWorkspaces()
        
        // Workspaces should be in cache now unless user is new and has no workspaces.
        return Workspace.current
    }
    
    func showCreateNewWorkspace() {
        // TODO
    }
}

