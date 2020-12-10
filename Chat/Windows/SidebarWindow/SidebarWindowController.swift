//
//  SidebarWindowController.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import AppKit

class SidebarWindowController: NSWindowController, NSWindowDelegate {
    
    // SidebarWindow is this controller's window type.
    typealias Window = SidebarWindow

    // No need to specify window during init --> just going to use 'Window' type.
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
        // Show main sidebar window.
        super.showWindow(sender)
        
        // Add and show team window as a child window.
        addTeamChildWindow()
    }
    
    private func addTeamChildWindow() {
        window!.addChildWindow(TeamWindow(), ordered: NSWindow.OrderingMode.above)
    }
}
