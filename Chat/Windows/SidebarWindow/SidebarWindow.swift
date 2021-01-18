//
//  SidebarWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Top-most window of our sidebar app.
class SidebarWindow: FloatingWindow {
    
    // Sidebar window styling information.
    enum Style {
        // Largest width the sidebar's contents should ever grow to.
        static let width: Int = 250
        
        // Height should match that of the entire screen.
        static let height = Screen.getHeight()
        
        // Window size.
        static let size = NSSize(width: Style.width, height: Style.height)

        // Window position.
        static let origin = NSPoint(x: Screen.getWidth() - Style.width, y: 0)
    }
    
    // Override delegated init and size/position window on screen.
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool) {
        
        // Pass up with no changes.
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // This will be the main window for our application.
        level = .mainMenu
        
        // Size and position window on screen.
        updateFrame(size: Style.size, position: Style.origin)
    }
}
