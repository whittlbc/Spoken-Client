//
//  MemberWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Supported member states.
enum MemberState {
    case idle
    case previewing
    case recording
}

class MemberWindow: FloatingWindow {

    // Workspace member associated with window.
    var member = Member()
    
    // The member's state on screen at any given time.
    var state = MemberState.idle
    
    // Proper initializer to use when rendering members.
    convenience init(member: Member) {
        self.init()
        self.member = member
    }
    
    // Override delegated init
    private override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    
    // TODO: Use member to modify these (notifications should increase width a bit for example)
    func getIdleWindowSize() -> NSSize {
        NSSize(width: 32, height: 32)
    }
    
    func getPreviewingWindowSize() -> NSSize {
        NSSize(width: 50, height: 50)
    }
    
    func getRecordingWindowSize() -> NSSize {
        NSSize(width: 162, height: 50)
    }
    
    func calculateSize() -> NSSize {
        switch state {
        // Default state
        case .idle:
            return getIdleWindowSize()
            
        // Hovering over a previously idle member
        case .previewing:
            return getIdleWindowSize()
            
        // Recording a message to this member
        case .recording:
            return getIdleWindowSize()
        }
    }
    
    // Render member window to a specific size and position.
    // TODO: Provide optional animatation params
    func render(size: NSSize, position: NSPoint) {
        resizeWindow(to: size)
        repositionWindow(to: position)
    }
    
//    override func mouseEntered(with event: NSEvent) {
//        if (isMouseInside) {
//            return
//        }
//
//        isMouseInside = true
//
//        makeKeyAndOrderFront(self)
//
//        backgroundColor = NSColor.white
//
//        var newFrame = frame
//        newFrame.origin.x -= 20
//        newFrame.size.width += 20
//
//        setFrame(newFrame, display: true)
//    }
//
//    override func mouseExited(with event: NSEvent) {
//        if (!isMouseInside) {
//            return
//        }
//
//        isMouseInside = false
//        backgroundColor = NSColor.clear
//
//        var newFrame = frame
//        newFrame.origin.x += 20
//        newFrame.size.width -= 20
//
//        setFrame(newFrame, display: true)
//    }
}
