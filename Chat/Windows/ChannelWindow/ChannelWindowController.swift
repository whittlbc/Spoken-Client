//
//  ChannelWindowController.swift
//  Chat
//
//  Created by Ben Whittle on 1/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

// Controller for channel window.
class ChannelWindowController: NSWindowController, NSWindowDelegate {
    
    // Channel associated with window.
    var channel: Channel!
    
    // Get window as channel window.
    var channelWindow: ChannelWindow { window as! ChannelWindow }
    
    // Controller of parent workspace window.
    weak var workspaceWindowController: WorkspaceWindowController?
    
    // Window's current size.
    var size: NSSize { ChannelWindow.Style.size(forState: state) }
    
    // Window's previous size.
    var prevSize: NSSize { ChannelWindow.Style.size(forState: prevState) }
    
    // Window's current position.
    var position: NSPoint { window!.frame.origin }
        
    // Latest height offset due to most recent state change.
    var latestHeightOffset: Float { Float(prevSize.height - size.height) / 2 }
    
    // Latest width offset due to most recent state change.
    var latestWidthOffset: Float { Float(prevSize.width - size.width) / 2 }
    
    // Whether this channel in its current state should cause adjacent channels to be disabled.
    var disablesAdjacentChannels: Bool { isRecording() }
        
    // Whether this channel should respond to interaction.
    var isDisabled: Bool { channelWindow.isDisabled }
    
    // Timer that double checks if the mouse is still inside this window when in the previewing state.
    private var previewingTimer: Timer?
    
    // Destination of window during active position animation.
    private var destination: NSPoint?

    // The channel's current state.
    private(set) var state = ChannelState.idle {
        didSet {
            prevState = oldValue
            publishedState = state
        }
    }

    // The channel's previous state.
    private(set) var prevState = ChannelState.idle

    // The state published to combine subscribers.
    @Published private(set) var publishedState = ChannelState.idle

    // Proper init to call when creating this class.
    convenience init(channel: Channel) {
        self.init(window: nil)
        
        // Store ref to channel.
        self.channel = channel
        
        // Add channel view controller as main content.
        addChannelViewController()
    }
    
    // Override delegated init.
    private override init(window: NSWindow?) {
        precondition(window == nil, "call init() with no window")
        
        // Initialize with new channel window.
        super.init(window: ChannelWindow())
        
        // Assign self as new channel window's delegate.
        self.window!.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Get window's animation destination -- fallback to frame origin.
    func getDestination() -> NSPoint {
        destination ?? position
    }
    
    // Set window's animation destination.
    func setDestination(_ origin: NSPoint) {
        destination = origin
    }

    // Handle mouse-enter event by state.
    func onMouseEntered() {
        switch state {
        case .idle:
            onMouseEnteredIdle()
        default:
            break
        }
    }
    
    // Handle mouse-exit event by state.
    func onMouseExited() {
        switch state {
        case .previewing:
            onMouseExitedPreviewing()
        default:
            break
        }
    }

    // Handle avatar click events.
    func onAvatarClick() {
        switch state {
        case .previewing:
            toRecordingInitializing()
        default:
            break
        }
    }
     
    // Whether the latest state update should render this channel individually or as a group.
    func shouldRenderIndividually() -> Bool {
        !stateChangedCase()
    }
    
    // Promote previous state to current state.
    func promotePreviousState() {
        prevState = state
    }
    
    // Check if currently in the idle state.
    func isIdle() -> Bool {
        return state == .idle
    }
    
    // Check if currently in the previewing state.
    func isPreviewing() -> Bool {
        return state == .previewing
    }
    
    // Check if currently in the recording state.
    func isRecording() -> Bool {
        return state == .recording(.initializing) // recording status is ignored here
    }
    
    // Check if currently in the recording:initializing state.
    func isRecordingInitializing() -> Bool {
        return state === .recording(.initializing)
    }
    
    // Check if currently in the recording:started state.
    func isRecordingStarted() -> Bool {
        return state === .recording(.started)
    }
    
    // Check if currently in the recording:cancelling state.
    func isRecordingCancelling() -> Bool {
        return state === .recording(.cancelling)
    }
    
    // Check if currently in the recording:sending state.
    func isRecordingSending() -> Bool {
        return state === .recording(.sending)
    }
    
    // Check if currently in the recording:sent state.
    func isRecordingSent() -> Bool {
        return state === .recording(.sent)
    }
    
    // Check if currently in the recording:finished state.
    func isRecordingFinished() -> Bool {
        return state === .recording(.finished)
    }
    
    // Set state to idle.
    func toIdle() {
        state = .idle
    }
    
    // Set state to previewing.
    func toPreviewing() {
        state = .previewing
    }
    
    // Set state to recording:initializing.
    func toRecordingInitializing() {
        state = .recording(.initializing)
    }
    
    // Set state to recording:started.
    func toRecordingStarted() {
        state = .recording(.started)
    }
    
    // Set state to recording:cancelling.
    func toRecordingCancelling() {
        state = .recording(.cancelling)
    }
    
    // Set state to recording:sending.
    func toRecordingSending() {
        state = .recording(.sending)
    }
    
    // Set state to recording:sent.
    func toRecordingSent() {
        state = .recording(.sent)
    }
    
    // Set state to recording:finished.
    func toRecordingFinished() {
        state = .recording(.finished)
    }
    
    // Check if the current state's case is different than the previous state's case.
    func stateChangedCase() -> Bool {
        return state != prevState
    }
    
    // Start a new audio message to send to this channel.
    func startRecording() {
        // Enable key event listners.
        toggleRecordingKeyListeners(enable: true)
        
        // Upsert an active recording.
        AV.mic.startRecording()
        
        // Set state to started recording.
        toRecordingStarted()
    }
    
    // Cancel recording and switch back to idle state.
    func cancelRecording() {
        // Disable key event listners.
        toggleRecordingKeyListeners(enable: false)
        
        // Stop and cler the active recording.
        AV.mic.stopRecording()
        AV.mic.clearRecording()

        // Show recording as cancelled.
        showRecordingCancelled()
    }
    
    // Send the active audio message to this channel.
    func sendRecording() {
        // Disable key event listners.
        toggleRecordingKeyListeners(enable: false)

        // Set state to sending recording.
        toRecordingSending()

        // Stop active recording.
        AV.mic.stopRecording()

        // TODO: Actually send recording...this will include a lot of steps...
        
        // Hack to simulate network time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            // Show recording as sent.
            self?.showRecordingSent()
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
    
    // Assume the mouse has exited the window, regardless of truth.
    func forceMouseExit() {
        channelWindow.registerMouseExited()
    }
    
    // Tell parent workspace window controller to toggle the recording-related global hot-keys.
    private func toggleRecordingKeyListeners(enable: Bool) {
        workspaceWindowController?.toggleRecordingKeyListeners(enable: enable)
    }
    
    // Ensure mouse is still inside this window; if not, force exit the mouse.
    @objc private func ensureStillPreviewing() {
        if !channelWindow.isMouseLocationInsideFrame() {
            forceMouseExit()
        }
    }

    // Mouse entered idle state --> update state to previewing.
    private func onMouseEnteredIdle() {
        toPreviewing()
    }
    
    // Mouse exited previewing state --> update state to idle.
    private func onMouseExitedPreviewing() {
        toIdle()
    }

    // Add channel view controller as this window's content view controller.
    private func addChannelViewController() {
        // Create new channel view controller.
        let channelViewController = ChannelViewController(channel: channel)
        
        // Set channel view controller as the primary content of the channel window.
        channelWindow.contentViewController = channelViewController

        // Bind channel window events to channel view controller.
        channelWindow.bind(.title, to: channelViewController, withKeyPath: "title", options: nil)
 
        // Make each channel view the first responder inside the channel window.
        channelWindow.makeFirstResponder(channelViewController.view)
    }
    
    // Show user that the recording has been successfully cancelled.
    private func showRecordingCancelled() {
        // Set state to cancelling recording.
        toRecordingCancelling()
        
        // Wait the tiniest amount of time, and then set state back to idle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.toIdle()
        }
    }
    
    // Show user that the recording has been successfully sent.
    private func showRecordingSent() {
        toRecordingSent()
        
        // Show recording sent for specific amount of time and then revert to idle state.
        DispatchQueue.main.asyncAfter(deadline: .now() + ChannelWindow.ArtificialTiming.showRecordingSentDuration) { [weak self] in
            self?.showRecordingFinished()
            
            // TODO: Move somewhere else once you're actually uploading recordings...?
            AV.mic.clearRecording()
        }
    }
    
    // Show user that the recording has successfully finished.
    private func showRecordingFinished() {
        // Set state to finished recording.
        toRecordingFinished()
        
        // Wait the tiniest amount of time, and then set state back to idle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.toIdle()
        }
    }
    
    // Use the current state to create a new channel render spec with proper size/position params.
    private func createRenderSpecFromState() -> ChannelRenderSpec {
        // Create a fresh render spec.
        var spec = ChannelRenderSpec()
        
        // Store current size and position refs.
        let currSize = size
        let currPos = position
        
        // Since state update has already occurred, use current size property as new spec size.
        spec.size = currSize
                
        // Adjust new position to account for new size, but keep the center origins the same.
        spec.position = NSPoint(
            x: currPos.x + CGFloat(latestWidthOffset),
            y: currPos.y + CGFloat(latestHeightOffset)
        )
        
        return spec
    }
    
    // Render the channel window with the given spec.
    private func renderWindow(_ spec: ChannelRenderSpec, _ state: ChannelState) {
        channelWindow.render(spec, state)
    }
    
    // Render window controller with render spec created from current state.
    func renderFromState() {
        render(createRenderSpecFromState())
    }
    
    // Render this window controller.
    func render(_ spec: ChannelRenderSpec) {
        // Render channel window.
        renderWindow(spec, state)
    }
}
