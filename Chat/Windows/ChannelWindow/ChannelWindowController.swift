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
        
    // The channel's current state.
    @Published private(set) var state = ChannelState.idle {
        didSet { prevState = oldValue }
    }
    
    // The channel's previous state.
    private(set) var prevState = ChannelState.idle

    // Proper init to call when creating this class.
    convenience init(channel: Channel) {
        self.init(window: nil)
        self.channel = channel
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
    
    // Show main window and add child windows.
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        // Add channel view controller
        addChannelViewController()
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
        return state == .recording(.starting) // recording status is ignored here
    }
    
    // Check if currently in the recording:starting state.
    func isRecordingStarting() -> Bool {
        return state === .recording(.starting)
    }
    
    // Check if the current state's case is different than the previous state's case.
    func stateChangedCase() -> Bool {
        return state != prevState
    }
    
    func startRecording() {
        
    }
    
    func cancelRecording() {
        
    }
    
    func sendRecording() {
        
    }
        
    func startPreviewingTimer() {
        
    }
    
    func cancelPreviewingTimer() {
        
    }
    
    func registerMouseExited() {
        
    }
    
    // Add channel view controller as this window's content view controller.
    private func addChannelViewController() {
        // Create new channel view controller.
        let channelViewController = ChannelViewController()
        
        // Set channel view controller as the primary content of the channel window.
        channelWindow.contentViewController = channelViewController

        // Bind channel window events to channel view controller.
        channelWindow.bind(.title, to: channelViewController, withKeyPath: "title", options: nil)
 
        // Make each channel view the first responder inside the channel window.
        channelWindow.makeFirstResponder(channelViewController.view)
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
    private func renderWindow(_ spec: ChannelRenderSpec) {
        channelWindow.render(spec)
    }
    
    // Render window controller with render spec created from current state.
    func renderFromState() {
        render(createRenderSpecFromState())
    }

    // Render this window controller.
    func render(_ spec: ChannelRenderSpec) {
        // Render channel window.
        renderWindow(spec)
    }
}
