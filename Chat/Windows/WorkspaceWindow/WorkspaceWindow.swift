//
//  WWindow.swift
//  Chat
//
//  Created by Ben Whittle on 1/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

// Window representing the current workspace.
class WorkspaceWindow: FloatingWindow {
    
    // Workspace window styling information.
    enum Style {
        // Size should match sidebar window.
        static let size = SidebarWindow.Style.size

        // Origin should match sidebar window.
        static let origin = SidebarWindow.Style.origin
        
        // Right padding of workspace window as it pertains to its content.
        static let paddingRight: Float = 6
        
        // X-position of this window's right edge.
        static let rightEdge = Float(Style.origin.x + Style.size.width) - Style.paddingRight

        // Distance between top of workspace window and first channel window.
        static let channelCeiling: Float = 240

        // Vertical spacing between channel windows.
        static let channelGutterSpacing: Float = 0
    }
    
    // Override delegated init and size/position window on screen.
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool) {
        
        // Pass up with no changes.
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
                
        // Position and size window on screen.
        repositionWindow(to: Style.origin)
        resizeWindow(to: Style.size)
    }
}
