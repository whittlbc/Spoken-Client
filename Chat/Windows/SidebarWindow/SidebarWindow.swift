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
    
    // Largest width the sidebar's contents should ever get to.
    static let width:Int = 250
            
    static let teamOffsetTop = 205
    
    // Override delegated init and size/position window on screen.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // This will be the main window for our application.
        level = .mainMenu
        
        // Right-align window to screen.
        repositionWindow(to: NSPoint(x: Screen.getWidth() - SidebarWindow.width, y: 0))
        
        // Set window frame size to take up the entire height of the screen.
        resizeWindow(to: NSSize(width: SidebarWindow.width, height: Screen.getHeight()))
    }
}
