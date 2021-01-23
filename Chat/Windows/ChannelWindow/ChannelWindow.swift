//
//  ChannelWindow.swift
//  Chat
//
//  Created by Ben Whittle on 1/18/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

// Window representing a workspace channel.
class ChannelWindow: FloatingWindow {
    
    // Channel window styling information.
    enum Style {
        
        // Idle window size.
        static let idleSize = NSSize(width: 32, height: 32)
        
        // Previewing window size.
        static let previewingSize = NSSize(width: 50, height: 50)
        
        // Recording window size.
        static let recordingSize = NSSize(width: 120, height: 120)
        
        // Default window size for the provided channel state.
        static func size(forState state: ChannelState) -> NSSize {
            switch state {
            
            // Idle size.
            case .idle:
                return idleSize
                
            // Previewing size.
            case .previewing:
                return previewingSize
                
            // Recording size.
            case .recording(let recordingStatus):
                return recordingStatus == .starting || recordingStatus == .cancelling ? previewingSize : recordingSize
            }
        }
    }
    
    // Channel window animation configuration.
    enum AnimationConfig {
        // Time it takes for a channel window to update size and position during a state change.
        static let duration: CFTimeInterval = 0.13

        // Name of timing function to use for all channel window animations.
        static let timingFunctionName = CAMediaTimingFunctionName.easeOut
    }
    
    // Artificial timing durations used in various places for better UX.
    enum ArtificialTiming {

        // How long to show window in the recording-sent state before reverting back to idle state.
        static let showRecordingSentDuration = 0.9
    }
    
    // Get delegate as channel window controller type.
    weak var channelWindowController: ChannelWindowController? { delegate as? ChannelWindowController }
    
    // Get content view controller as channel view controller.
    var channelViewController: ChannelViewController { contentViewController as! ChannelViewController }
    
    // Whether this window should respond to interaction.
    var isDisabled = false
    
    // Flag indicating whether mouse is inside window.
    var isMouseInside = false
    
    func isMouseLocationInsideFrame(loc: NSPoint? = nil) -> Bool {
        frame.isLocationInside(loc ?? mouseLocationOutsideOfEventStream)
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
        if isMouseLocationInsideFrame(loc: event.locationInWindow) {
            return
        }
        
        registerMouseExited()
    }
    
    // Mouse just entered the window.
    func registerMouseEntered() {
        isMouseInside = true

        // Make this window the key window as order it to front.
        makeKeyAndOrderFront(self)

        // Bubble up mouse-entered event to delegate.
        channelWindowController?.onMouseEntered()
    }
    
    // Mouse just exited the window.
    func registerMouseExited() {
        isMouseInside = false
        
        // Bubble up mouse-exited event to delegate.
        channelWindowController?.onMouseExited()
    }

    private func updateDisability(to value: Bool) {
        isDisabled = value
    }
    
    private func applyStatefulSpecProps(_ spec: ChannelRenderSpec) {
        updateDisability(to: spec.isDisabled)
    }
    
    // Render window frame.
    func renderFrame(_ spec: ChannelRenderSpec) {
        updateFrame(size: spec.size, position: spec.position)
    }
    
    // Render channel view content.
    func renderContent(_ spec: ChannelRenderSpec) {
        channelViewController.render(spec)
    }
    
    // Render window to size/position.
    func render(_ spec: ChannelRenderSpec) {
        // Apply any spec props that should be stored as props of this class instance.
        applyStatefulSpecProps(spec)

        // Render frame.
        renderFrame(spec)
        
        // Render content.
        renderContent(spec)
    }
}
