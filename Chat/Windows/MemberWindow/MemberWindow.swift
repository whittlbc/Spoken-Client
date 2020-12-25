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
    
    // The last state a member was in.
    var prevState = MemberState.idle
    
    // Flag indicating whether mouse is inside window.
    var isMouseInside = false
    
    // Whether member is able to be interacted with by the user.
    var isDisabled = false
        
    // Closure provided by parent window to be called every time state updates.
    private var onStateUpdated: ((String) -> Void)!
    
    // TODO: Switch to non-private computed property
    // The latest origin this window will-animate/has-animated to.
    private var destination: NSPoint?
    
    // Timer that double checks the mouse is still inside this window if its in the previewing state.
    // State will be forced out of the previewing state if the mouse is not.
    private var previewingTimer: Timer?
    
    // Get the default window size for the provided member state.
    static func defaultSizeForState(_ state: MemberState) -> NSSize {
        switch state {
        case .idle:
            return NSSize(width: 32, height: 32)
        case .previewing:
            return NSSize(width: 50, height: 50)
        case .recording:
            return NSSize(width: 50, height: 50)
        }
    }
    
    enum RecordingStyle {
        static let size = NSSize(width: 120, height: 120)
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
    
    // Check whether member window is currently in the idle state.
    func isIdle() -> Bool {
        state == .idle
    }
    
    // Check whether member window is currently in the idle state.
    func isPreviewing() -> Bool {
        state == .previewing
    }
    
    // Check whether member window is currently in the idle state.
    func isRecording() -> Bool {
        state == .recording
    }
    
    // Get MemberViewController --> this window's primary content view controller.
    func getMemberViewController() -> MemberViewController? {
        guard let memberViewController = contentViewController as? MemberViewController else {
            logger.error("Unable to find MemberWindow's contentViewController...")
            return nil
        }
        
        return memberViewController
    }

    // Get MemberView --> this window's primary content view.
    func getMemberView() -> MemberView? {
        // Get this window's content view controller.
        guard let viewController = getMemberViewController() else {
            return nil
        }
        
        // Get this window's content view.
        guard let memberView = viewController.view as? MemberView else {
            logger.error("Unable to find MemberViewController's MemberView...")
            return nil
        }
        
        return memberView
    }
    
    // Update state of member view to match that of this window.
    func updateViewState(isDisabled disabled: Bool? = nil) {
        // Get member view.
        guard let memberView = getMemberView() else {
            return
        }
        
        // Update disabled status if provided.
        if let newDisabledStatus = disabled {
            isDisabled = newDisabledStatus
        }
        
        // Update member view's state if it differs from this window's state.
        memberView.setState(state, isDisabled: disabled)
    }
    
    // Promote previous state to current state.
    func promotePreviousState() {
        prevState = state
    }
    
    func startRecording() {}
    
    // Cancel recording and switch back to idle state.
    func cancelRecording() {
        removeRecordingStyle()
        setState(.idle)
    }
    
    // Get window's animation destination -- fallback to frame origin.
    func getDestination() -> NSPoint {
        destination ?? frame.origin
    }
    
    // Set window's animation destination.
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
    
    // Get the size of this window for the given state.
    func calculateSize(forState memberState: MemberState) -> NSSize {
        switch memberState {
        // Idle window size.
        case .idle:
            return getIdleWindowSize()
            
        // Previewing window size.
        case .previewing:
            return getPreviewingWindowSize()

        // Recording window size.
        case .recording:
            return getRecordingWindowSize()
        }
    }
    
    // Get the positional offset for this window due its latest state change.
    func getStateChangeSizeOffset() -> (Float, Float) {
        let prevSize = calculateSize(forState: prevState)
        let currentSize = calculateSize(forState: state)
        
        return (
            Float(prevSize.height - currentSize.height) / 2,
            Float(prevSize.width - currentSize.width) / 2
        )
    }
    
    // Get window size for the current state.
    func getSizeForCurrentState() -> NSSize {
        calculateSize(forState: state)
    }
    
    // Update size/position of window and contents to fit recording animations.
    func addRecordingStyle() {
        // Get member view controller and view.
        guard let memberViewController = getMemberViewController(), let memberView = getMemberView() else {
            return
        }
                
        // Calculate new position of recording-style window.
        let newPosition = getRecordingStyleWindowPosition()
    
        // Update window size and position.
        resizeWindow(to: RecordingStyle.size)
        repositionWindow(to: newPosition)
    
        // Add member view's recording style.
        memberView.addRecordingStyle()
        
        // Add particle lab.
        memberViewController.addParticleLab()
    }
    
    // Revert size/position updates added during recording.
    func removeRecordingStyle() {
        // Get member view controller and view.
        guard let memberViewController = getMemberViewController(), let memberView = getMemberView() else {
            return
        }

        // Get previous size and position of window before recording style was added.
        let prevSize = calculateSize(forState: prevState)
        
        // Update window size and position.
        resizeWindow(to: prevSize)
        repositionWindow(to: destination!)
        
        // Remove member view's recording style.
        memberView.removeRecordingStyle()
        
        // Remove particle lab.
        memberViewController.removeParticleLab()
    }
    
    // Create new position for window based on size of recording style.
    func getRecordingStyleWindowPosition() -> NSPoint {
        let currSize = frame.size
        let currPos = frame.origin
        
        let widthOffset = (currSize.width - RecordingStyle.size.width) / 2
        let heightOffset = (currSize.height - RecordingStyle.size.height) / 2
                
        let newX = currPos.x + widthOffset
        let newY = currPos.y + heightOffset
        
        return NSPoint(x: newX, y: newY)
    }

    // Handle mouse-entered event.
    override func mouseEntered(with event: NSEvent) {
        if isMouseInside || isDisabled {
            return
        }
        
        registerMouseEntered()
    }
    
    // Handle mouse-exited event.
    override func mouseExited(with event: NSEvent) {
        // If mouse is already outside the window, do nothing.
        if !isMouseInside || isDisabled {
            return
        }

        // Double check that the mouse's location is actually outside this frame.
        // This prevents the mouse-exited events that come through rapidly whenever
        // this window is programmatically resized.
        if frame.isLocationInside(event.locationInWindow) {
            return
        }
        
        registerMouseExited()
    }
    
    // Mouse just entered the window.
    func registerMouseEntered() {
        isMouseInside = true

        // Make this window the key window as order it to front.
        makeKeyAndOrderFront(self)

        // Handle mouse-entered event on a state-specific level.
        switch state {
        case .idle:
            onMouseEnteredIdle()
        default:
            break
        }
    }
    
    // Mouse just exited the window.
    func registerMouseExited() {
        isMouseInside = false
        
        // Handle mouse-exited event on a state-specific level.
        switch state {
        case .previewing:
            onMouseExitedPreviewing()
        default:
            break
        }
    }

    // Mouse entered idle state --> update state to previewing.
    private func onMouseEnteredIdle() {
        setState(.previewing)
    }
    
    // Mouse exited previewing state --> update state to idle.
    private func onMouseExitedPreviewing() {
        setState(.idle)
    }

    // Ensure mouse is still inside this window...if it's not, manually register mouse as exited.
    @objc private func ensureStillPreviewing() {
        if !frame.isLocationInside(mouseLocationOutsideOfEventStream) {
            registerMouseExited()
        }
    }
    
    // Start timer used to check whether mouse is still inside the previewing window.
    func startPreviewingTimer() {
        if previewingTimer != nil {
            return
        }
        
        // Create timer that repeats call to self.ensureStillPreviewing every 150ms.
        previewingTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(0.15),
            target: self,
            selector: #selector(ensureStillPreviewing),
            userInfo: nil,
            repeats: true
        )
    }
    
    // Invalidate previewing timer and reset to nil if it exists.
    func cancelPreviewingTimer() {
        if previewingTimer == nil {
            return
        }
        
        previewingTimer!.invalidate()
        previewingTimer = nil
    }
    
    // Handle avatar mouse-up events.
    func onAvatarClick() {
        // Update state to recording if clicking avatar while previewing.
        if state == .previewing {
            setState(.recording)
        }
    }
    
    // Update this window's state.
    func setState(_ newState: MemberState) {
        // Promote previous state to current state.
        promotePreviousState()
        
        // Update current state to provided new state.
        state = newState
        
        // Tell parent window that state was updated.
        onStateUpdated(member.id)
        
        // Handle state-specific change.
        switch state {
        case .idle:
            onIdle()
        case .previewing:
            onPreviewing()
        case .recording:
            onRecording()
        }
    }

    // Handler called when state updates to idle.
    private func onIdle() {
        // Invalidate previewing timer if it exists.
        cancelPreviewingTimer()
    }
    
    // Handler called when state updates to previewing.
    private func onPreviewing() {}
    
    // Handler called when state updates to recording.
    private func onRecording() {
        // Invalidate previewing timer if it exists.
        cancelPreviewingTimer()
    }
    
    // Render member window to a specific size and position.
    func render(size: NSSize, position: NSPoint) {
        resizeWindow(to: size)
        repositionWindow(to: position)
    }
}
