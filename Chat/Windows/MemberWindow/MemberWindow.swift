//
//  MemberWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Supported member states.
enum MemberState: String {
    case idle
    case previewing
    case recording
}

// Window representing a workspace member.
class MemberWindow: FloatingWindow {

    // Workspace member associated with window.
    var member = Member()
    
    // The member's state on screen at any given time.
    var state = MemberState.idle
    var prevState = MemberState.idle
    
    // Flag indicating whether mouse is inside window.
    var isMouseInside = false
        
    // Closure provided by parent window for when state updates.
    var onStateUpdated: ((String) -> Void)!
    
    var destination: NSPoint?
    
    var resizing = false
    
    var leftWhileResizing = false
    
    var previewingTimer: Timer?
    
    static func defaultSizeForState(_ state: MemberState) -> NSSize {
        switch state {
        case .idle:
            return NSSize(width: 32, height: 32)
        case .previewing:
            return NSSize(width: 50, height: 50)
        case .recording:
            return NSSize(width: 162, height: 50)
        }
    }
    
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
    
    func updateViewState() {
        guard let viewController = contentViewController else {
            logger.error("Unable to find MemberWindow's contentViewController...")
            return
        }
        
        guard let memberView = viewController.view as? MemberView else {
            logger.error("Unable to find MemberViewController's MemberView...")
            return
        }
        
        // Don't update unless a diff exists.
        if memberView.state == state {
            return
        }
        
        memberView.setState(state)
    }
    
    // Promote previous state to current state.
    func promotePreviousState() {
        prevState = state
    }
    
    func getDestination() -> NSPoint {
        destination ?? frame.origin
    }
    
    func setDestination(_ origin: NSPoint) {
        destination = origin
    }
    
    // TODO: Add member-specific sizes on top of this once notifications are added.
    func getIdleWindowSize() -> NSSize {
        MemberWindow.defaultSizeForState(.idle)
    }
    
    // TODO: Add member-specific sizes on top of this once notifications are added.
    func getPreviewingWindowSize() -> NSSize {
        MemberWindow.defaultSizeForState(.previewing)
    }
    
    // TODO: Add member-specific sizes on top of this once notifications are added.
    func getRecordingWindowSize() -> NSSize {
        MemberWindow.defaultSizeForState(.recording)
    }
    
    // Get the size of this window for a given state.
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
    
    func getStateChangeSizeOffset() -> (Float, Float) {
        let prevSize = calculateSize(forState: prevState)
        let size = calculateSize(forState: state)
        
        return (
            Float(prevSize.height - size.height) / 2,
            Float(prevSize.width - size.width) / 2
        )
    }
    
    func getSizeForCurrentState() -> NSSize {
        calculateSize(forState: state)
    }
    
    override func mouseEntered(with event: NSEvent) {
        // If mouse has already entered, do nothing.
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
        // If mouse has already exited, do nothing.
        if !isMouseInside {
            return
        }
        
        let loc = event.locationInWindow
        let size = frame.size
        
        let isOutsideXBounds = loc.x < 0 || loc.x > size.width
        let isOutsideYBounds = loc.y < 0 || loc.y > size.height
        
        if !isOutsideXBounds && !isOutsideYBounds {
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
    
    func forceMouseExit() {
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
    
    @objc func ensureStillPreviewing() {
        let loc = mouseLocationOutsideOfEventStream
        let size = frame.size
        
        let isOutsideXBounds = loc.x < 0 || loc.x > size.width
        let isOutsideYBounds = loc.y < 0 || loc.y > size.height
        
        if isOutsideXBounds || isOutsideYBounds {
            if previewingTimer != nil {
                previewingTimer?.invalidate()
                previewingTimer = nil
            }
            
            isMouseInside = false
            onMouseExitedPreviewing()
        }
    }
    
    func startPreviewingTimer() {
        if previewingTimer != nil {
            return
        }
        
        previewingTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(0.15),
            target: self,
            selector: #selector(ensureStillPreviewing),
            userInfo: nil,
            repeats: true
        )
    }
    
    func setState(_ newState: MemberState) {
        prevState = state
        state = newState
        onStateUpdated(member.id)
        
        if state != .previewing && previewingTimer != nil {
            previewingTimer?.invalidate()
            previewingTimer = nil
        }
    }
        
    // Render member window to a specific size and position.
    func render(size: NSSize, position: NSPoint) {
        resizeWindow(to: size)
        repositionWindow(to: position)
    }
}
