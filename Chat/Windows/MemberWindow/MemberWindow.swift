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
    var prevState = MemberState.idle
    
    // Flag indicating whether mouse is inside window.
    var isMouseInside = false
    
    // Flag indicating whether window has rendered for the first time.
    var initialPositionSet = false
    
    // Closure provided by parent window for when state updates.
    var onStateUpdated: ((String) -> Void)!
    
    // Proper initializer to use when rendering members.
    convenience init(member: Member, onStateUpdated: @escaping (String) -> Void) {
        self.init()
        self.member = member
        self.onStateUpdated = onStateUpdated
    }
    
    // Override delegated init
    private override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    
    func registerStateUnchanged() {
        prevState = state
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
    
    func calculateSize(forState memberState: MemberState) -> NSSize {
        switch memberState {
        // Default state
        case .idle:
            return getIdleWindowSize()
            
        // Hovering over a previously idle member
        case .previewing:
            return getPreviewingWindowSize()
            
        // Recording a message to this member
        case .recording:
            return getRecordingWindowSize()
        }
    }
    
    // (Old Height - New Height) / 2
    func getVerticalOffsetForStateChange() -> Float {
        Float(calculateSize(forState: prevState).height - calculateSize(forState: state).height) / 2
    }
    
    // Render member window to a specific size and position.
    // TODO: Provide optional animatation params
    func render(size: NSSize, position: NSPoint) {
        resizeWindow(to: size)
        repositionWindow(to: position)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if isMouseInside {
            return
        }
        
        isMouseInside = true
        
        makeKeyAndOrderFront(self)

        switch state {
        case .idle:
            onMouseEnteredIdle()
        default:
            break
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !isMouseInside {
            return
        }
        
        isMouseInside = false
        
        switch state {
        case .previewing:
            onMouseExitedPreviewing()
        default:
            break
        }
    }
    
    func onMouseEnteredIdle() {
        setState(.previewing)
    }
    
    func onMouseExitedPreviewing() {
        setState(.idle)
    }
    
    func setState(_ newState: MemberState) {
        prevState = state
        state = newState
        onStateUpdated(member.id)
    }
}
