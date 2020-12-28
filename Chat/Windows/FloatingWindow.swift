//
//  FloatingWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Transparent window that always "floats" above all other apps, even when its not active.
// Use this window as a container window for other floating windows that actually have content within your app.
class FloatingWindow: NSPanel {
    
    // Override delgated init to style window as transparent/floating.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // Float above all other applications and windows.
        level = .floating
        
        // Don't let it ever go away and prevent it from becoming an "active" window upon click.
        hidesOnDeactivate = false
        styleMask.insert(.nonactivatingPanel)

        // Make it transparent.
        isOpaque = false
        hasShadow = false
        backgroundColor = NSColor.clear
        styleMask.insert(.borderless)
        
        // Don't allow it to be dragged or resized.
        isMovableByWindowBackground = false
        styleMask.remove(.resizable)
        
        // Still give it a top-level application menu bar when active.
        isExcludedFromWindowsMenu = false
        
        // Allow the window to join all desktop "spaces".
        collectionBehavior = [.canJoinAllSpaces]
        
        // Remove toolbar and title.
        toolbar = nil
        titleVisibility = .hidden
        styleMask.remove(.titled)
    }
 
    // Allow it to become 'main' window.
    override var canBecomeMain: Bool { true }
    
    // Allow it to become 'key' window.
    override var canBecomeKey: Bool { true }
    
    override var isReleasedWhenClosed: Bool {
        get { true }
        @available(*, unavailable)
        set {
            // Ignore AppKit's attempts to set this property
        }
    }

    override func cancelOperation(_ sender: Any?) {
        // Override default behavior to prevent panel from closing
    }
    
    // Reposition the window.
    func repositionWindow(to origin: NSPoint) {
        setFrameOrigin(origin)
    }
    
    // Resize the window.
    func resizeWindow(to size: NSSize) {
        var newFrame = frame
        newFrame.size = size
        setFrame(newFrame, display: true)
    }
    
    // Update the windows frame for the given size and position (if provided) with an optional animation.
    func updateFrame(size: NSSize? = nil, position: NSPoint? = nil, animate: Bool = false) {
        if size == nil && position == nil {
            return
        }
        
        let newSize = size ?? frame.size
        let newPosition = position ?? frame.origin

        let newFrame = NSRect(
            x: newPosition.x,
            y: newPosition.y,
            width: newSize.width,
            height: newSize.height
        )
        
        if animate {
            animator().setFrame(newFrame, display: true)
        } else {
            setFrame(newFrame, display: true)
        }
    }
}
