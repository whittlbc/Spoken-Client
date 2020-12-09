//
//  FloatingWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class FloatingWindow: NSPanel {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        level = .floating
        hidesOnDeactivate = false
        hasShadow = false
        isMovableByWindowBackground = false
        isExcludedFromWindowsMenu = false
        collectionBehavior = [.canJoinAllSpaces]
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = NSColor.clear
        styleMask.insert(.nonactivatingPanel)
        styleMask.insert(.borderless)
        styleMask.remove(.titled)
        styleMask.remove(.resizable)
        toolbar = nil
    }
 
    override var canBecomeMain: Bool {
        true
    }
    
    override var canBecomeKey: Bool {
        true
    }
    
    override var isReleasedWhenClosed: Bool {
        get {
            true
        }
        @available(*, unavailable)
        set {
            // Ignore AppKit's attempts to set this property
        }
    }
    
    override func makeKey() {
        super.makeKey()
        NSApplication.shared.addWindowsItem(self, title: title, filename: false)
    }
    
    override func cancelOperation(_ sender: Any?) {
        // Override default behavior to prevent panel from closing
    }
}
