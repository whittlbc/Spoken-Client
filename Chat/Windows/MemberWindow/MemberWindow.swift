//
//  MemberWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

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
    
    // Window styling info.
    enum Style {
        
        // Artificial timing used for better UX.
        enum ArtificialTiming {
        
            // How long to show window in the recording-sent state before reverting back to idle.
            static let showRecordingSentDuration = 0.9
        }
    }
    
    // Get the default window size for the provided member state.
    static func defaultSizeForState(_ state: MemberState) -> NSSize {
        switch state {
        case .idle:
            return NSSize(width: 32, height: 32)
        case .previewing:
            return NSSize(width: 50, height: 50)
        case .recording(let recordingStatus):
            return recordingStatus == .starting || recordingStatus == .cancelling ?
                NSSize(width: 50, height: 50) : NSSize(width: 120, height: 120)
        }
    }
    
    static func stateShouldAnimateFrame(_ state: MemberState) -> Bool {
        state != .recording(.starting) // recording status is ignored here
    }
    
    static func stateShouldDisableOtherMembers(_ state: MemberState) -> Bool {
        state == .recording(.starting) // recording status is ignored here
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
    
    // Get parent workspace window.
    func getWorkspaceWindow() -> WorkspaceWindow? {
        guard let workspaceWindow = parent as? WorkspaceWindow else {
            logger.error("Unable to find MemberWindow's parent Workspace window...")
            return nil
        }
        
        return workspaceWindow
    }
    
    // Get MemberViewController --> this window's primary content view controller.
    func getMemberViewController() -> MemberViewController? {
        guard let memberViewController = contentViewController as? MemberViewController else {
            logger.error("Unable to find MemberWindow's contentViewController...")
            return nil
        }
        
        return memberViewController
    }
    
    // Promote previous state to current state.
    func promotePreviousState() {
        prevState = state
    }
    
    // Check whether member window is currently in the idle state.
    func isIdle() -> Bool {
        return state == .idle
    }
    
    // Check whether member window is currently in the previewing state.
    func isPreviewing() -> Bool {
        return state == .previewing
    }
    
    // Check whether member window is currently in the recording state.
    func isRecording() -> Bool {
        return state == .recording(.starting) // recording status is ignored here
    }
    
    // Update this window's state.
    func setState(_ newState: MemberState) {
        // Promote previous state to current state.
        promotePreviousState()
        
        // Update current state to provided new state.
        state = newState
        
        // If the state changed cases, broadcast this update.
        if state != prevState {
            onStateUpdated(member.id)
        }
        
        // Handle state-specific change.
        switch state {
        case .idle:
            onIdle()
        case .previewing:
            onPreviewing()
        case .recording(_):
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

    // Start a new audio message to send to this member.
    func startRecording() {
        // Enable key event listners.
        toggleRecordingKeyEventListeners(enable: true)
        
        // TODO: Actually start a recording...
        
        // Show recording as started.
        showStartedRecording()
    }
    
    // Cancel recording and switch back to idle state.
    func cancelRecording() {
        // Disable key event listners.
        toggleRecordingKeyEventListeners(enable: false)
        
        // TODO: Actually cancel the recording...

        // Show recording as cancelled.
        showCancellingRecording()
    }
    
    // Send the active audio message to this member.
    func sendRecording() {
        // Disable key event listners.
        toggleRecordingKeyEventListeners(enable: false)

        // Render state to recording-sending.
        showSendingRecording()
        
        // TODO: Actually send the recording...
        // HACK to simulate network time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showSentRecording()
        }
    }

    // Tell parent workspace window to toggle on/off the key-event listeners tied to recording.
    func toggleRecordingKeyEventListeners(enable: Bool) {
        guard let workspaceWindow = getWorkspaceWindow() else {
            return
        }
        
        workspaceWindow.toggleRecordingKeyEventListeners(enable: enable)
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
    func getRecordingWindowSize(recordingStatus: RecordingStatus) -> NSSize {
        MemberWindow.defaultSizeForState(.recording(recordingStatus))
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
        case .recording(let recordingStatus):
            return getRecordingWindowSize(recordingStatus: recordingStatus)
        }
    }
    
    // Get the positional offset for this window due its latest state change.
    func getStateChangeSizeOffset() -> (Float, Float) {
        let prevSize = calculateSize(forState: prevState)
        let currentSize = getSizeForCurrentState()
        
        return (
            Float(prevSize.height - currentSize.height) / 2,
            Float(prevSize.width - currentSize.width) / 2
        )
    }
    
    // Get window size for the current state.
    func getSizeForCurrentState() -> NSSize {
        calculateSize(forState: state)
    }
    
    // Create new position for window based on size of recording style.
    func getRecordingStyleWindowPosition(newSize: NSSize) -> NSPoint {
        let currSize = frame.size
        let currPos = frame.origin
        
        let widthOffset = (currSize.width - newSize.width) / 2
        let heightOffset = (currSize.height - newSize.height) / 2
                
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
        if isDisabled {
            return
        }
        
        // Update state to starting recording if clicking avatar while previewing.
        if isPreviewing() {
            setState(.recording(.starting))
        }
    }
        
    // Update isDisabled value (if different) and return if value was changed.
    private func updateDisabled(disabled: Bool?) -> Bool {
        if let newDisabledStatus = disabled, newDisabledStatus != isDisabled {
            isDisabled = newDisabledStatus
            return true
        }
        
        return false
    }
    
    func showStartedRecording() {
        // Update state to started recording.
        setState(.recording(.started))
        
        // Get the size for the new state.
        let newSize = getSizeForCurrentState()
        
        // Render to new frame (without animation) and propagate render down-chain.
        render(
            size: newSize,
            position: getRecordingStyleWindowPosition(newSize: newSize),
            propagate: true
        )
    }
        
    func showCancellingRecording() {
        // Update state to cancelling recording.
        setState(.recording(.cancelling))
                
        // Render to new frame (without animation) and propagate render down-chain.
        render(
            size: getSizeForCurrentState(),
            position: destination!,
            propagate: true
        )
        
        // Update state to idle now so that an animation is triggered.
        setState(.idle)
    }
    
    func showSendingRecording() {
        // Update state to sending recording.
        setState(.recording(.sending))
        
        // Propagage a render down-chain.
        render(propagate: true)
    }
    
    func showSentRecording() {
        // Update state to sent recording.
        setState(.recording(.sent))
        
        // Propagage a render down-chain.
        render(propagate: true)

        // Show recording sent for specific amount of time and then revert to idle state.
        DispatchQueue.main.asyncAfter(deadline: .now() + Style.ArtificialTiming.showRecordingSentDuration) { [weak self] in
            // Follow the cancelling recording flow to get back to idle state.
            self?.showCancellingRecording()
        }
    }
    
    // Render member view -- this windows primary content view.
    private func renderMemberView(disabledChanged: Bool = false) {
        // Get member view controller.
        guard let memberViewController = getMemberViewController() else {
            return
        }
        
        // Render member view and only provide isDisabled if it changed since last render.
        memberViewController.render(state: state, isDisabled: disabledChanged ? isDisabled : nil)
    }
    
    // Render this windows children.
    private func renderChildren(disabledChanged: Bool = false) {
        renderMemberView(disabledChanged: disabledChanged)
    }
    
    func render(
        size: NSSize? = nil,
        position: NSPoint? = nil,
        isDisabled disabled: Bool? = nil,
        propagate: Bool = false,
        animate: Bool = false) {
        
        // Update window frame.
        updateFrame(size: size, position: position, animate: animate)
        
        // Update isDisabled and see if it changed at all.
        let disabledChanged = updateDisabled(disabled: disabled)
        
        // Propagate render down to children if specified.
        if propagate {
            renderChildren(disabledChanged: disabledChanged)
        }
    }
}
