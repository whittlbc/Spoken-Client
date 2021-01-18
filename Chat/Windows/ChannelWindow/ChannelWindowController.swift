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
    
    // Window's current size.
    var size: NSSize { ChannelWindow.Style.size(forState: state) }
    
    // Window's previous size.
    var prevSize: NSSize { ChannelWindow.Style.size(forState: prevState) }
    
    // Window's current position.
    var position: NSPoint { window!.frame.origin }
    
    // Latest height offset due to most recent state change.
    var latestHeightOffset: Float { Float(prevSize.height - size.height) / 2 }
    
    // Whether this channel in its current state should cause adjacent channels to be disabled.
    var disablesAdjacentChannels: Bool { state == .recording(.starting) }
        
    // The channel's current state.
    @Published private(set) var state = ChannelState.idle {
        didSet {
            prevState = oldValue
            onStateSet()
        }
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
    
    func setAppearance(size: NSSize, position: NSPoint) {
        (window as! ChannelWindow).updateFrame(size: size, position: position)
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
    
    func registerMouseExited() {
        
    }
        
    private func onStateSet() {
        // Cancel the previewing timer if not previewing.
        if !isPreviewing() {
//            cancelPreviewingTimer()
        }
    }
    
    // Add channel view controller as this window's content view controller.
    private func addChannelViewController() {
        guard let channelWindow = window else {
            return
        }
        
        // Create new channel view controller.
        let channelViewController = ChannelViewController()
        
        // Set channel view controller as the primary content of the channel window.
        channelWindow.contentViewController = channelViewController

        // Bind channel window events to channel view controller.
        channelWindow.bind(.title, to: channelViewController, withKeyPath: "title", options: nil)
 
        // Make each channel view the first responder inside the channel window.
        channelWindow.makeFirstResponder(channelViewController.view)
    }
    
    func render(_ spec: ChannelRenderSpec) {
        
    }
}
