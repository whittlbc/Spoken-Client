//
//  SidebarWindowController.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import AppKit

// Controller for sidebar window.
class SidebarWindowController: NSWindowController, NSWindowDelegate {
    
    // SidebarWindow is this controller's window type.
    typealias Window = SidebarWindow

    // Window will be set to the above "Window" type, so no need to make the user set this during init.
    convenience init() {
        self.init(window: nil)
    }
    
    // Override delegated init -- initialize 'Window' type window.
    private override init(window: NSWindow?) {
        precondition(window == nil, "call init() with no window")
        
        // Initialize with new sidebar window.
        super.init(window: Window())
        
        // Assign self as new sidebar window's delegate.
        self.window!.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Show main window and add child windows.
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        // Add workspace window as a child window.
        addWorkspaceWindow()
    }
    
    // Add workspace window as a child window.
    private func addWorkspaceWindow() {
        // Create new workspace window.
        let workspaceWindow = WorkspaceWindow()
        
        // Add workspace window as top-most child window.
        window!.addChildWindow(workspaceWindow, ordered: NSWindow.OrderingMode.above)
        
        // Load current workspace.
        workspaceWindow.loadCurrentWorkspace()
    }
}
