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
        static let idleSize = NSSize(width: 30, height: 30)
        
        // Previewing window size.
        static let previewingSize = NSSize(width: 48, height: 48)
        
        // Recording window size.
        static func recordingSize(withVideo: Bool) -> NSSize {
            withVideo ? NSSize(width: 143, height: 143) : NSSize(width: 120, height: 120)
        }
        
        // Recording window size as it appears to an adjacent channel window.
        static func externalRecordingSize(withVideo: Bool) -> NSSize {
            withVideo ? NSSize(width: 110, height: 110) : NSSize(width: 120, height: 120)
        }
        
        // Consuming window size.
        static func consumingSize(withVideo: Bool) -> NSSize {
            withVideo ? NSSize(width: 143, height: 143) : NSSize(width: 120, height: 120)
        }
        
        // Consuming window size as it appears to an adjacent channel window.
        static func externalConsumingSize(withVideo: Bool) -> NSSize {
            withVideo ? NSSize(width: 110, height: 110) : NSSize(width: 120, height: 120)
        }
        
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
                switch recordingStatus {
                
                // Initializing recording.
                case .initializing:
                    return previewingSize
                
                // Cancelling or finished recording.
                case .cancelling, .finished:
                    return UserSettings.Video.useCamera ? recordingSize(withVideo: true) : previewingSize
                
                // All other recording statuses.
                default:
                    return recordingSize(withVideo: UserSettings.Video.useCamera)
                }
                
            // Consuming size.
            case .consuming(let message, let consumingStatus):
                switch consumingStatus {
                
                // Cancelling or finished consuming.
                case .cancelling, .finished:
                    return message.isVideo ? consumingSize(withVideo: true) : previewingSize
                
                // All other consuming statuses.
                default:
                    return consumingSize(withVideo: message.isVideo)
                }
            }
        }
        
        // Size of channel window as it appears to other adjacent channels (can be faked).
        static func externalSize(forState state: ChannelState) -> NSSize {
            switch state {
            
            // For idle or previewing, just return regular size.
            case .idle, .previewing:
                return size(forState: state)
                
            // Recording size.
            case .recording(let recordingStatus):
                switch recordingStatus {
                
                // Initializing recording.
                case .initializing:
                    return size(forState: state)

                // Cancelling or finished recording.
                case .cancelling, .finished:
                    return UserSettings.Video.useCamera ? externalRecordingSize(withVideo: true) : size(forState: state)
                
                // All other recording statuses.
                default:
                    return externalRecordingSize(withVideo: UserSettings.Video.useCamera)
                }
            
            // Consuming size.
            case .consuming(let message, let consumingStatus):
                switch consumingStatus {
                
                // Cancelling or finished consuming.
                case .cancelling, .finished:
                    return message.isVideo ? externalConsumingSize(withVideo: true) : size(forState: state)
                
                // All other consuming statuses.
                default:
                    return externalConsumingSize(withVideo: message.isVideo)
                }
            }
        }
        
        static func adjacentChannelOffset(forState state: ChannelState) -> AdjacentChannelOffset {
            switch state {
            
            case .idle, .previewing:
                return AdjacentChannelOffset()
                
            case .recording(let recordingStatus):
                switch recordingStatus {
                
                case .started:
                    return UserSettings.Video.useCamera ? AdjacentChannelOffset(above: 0, below: -9.0) : AdjacentChannelOffset()

                default:
                    return AdjacentChannelOffset()
                }
                
            case .consuming(let message, let consumingStatus):
                switch consumingStatus {
                
                case .started:
                    return message.isVideo ? AdjacentChannelOffset(above: 0, below: -9.0) : AdjacentChannelOffset()

                default:
                    return AdjacentChannelOffset()
                }
            }
        }
    }
    
    // Channel window animation configuration.
    enum AnimationConfig {
        // Time it takes for a channel window to update size and position during a state change.
        static func duration(forState state: ChannelState?) -> CFTimeInterval {
            let resolvedState = state ?? ChannelState.idle
            
            switch resolvedState {
            
            // Idle and previewing.
            case .idle, .previewing:
                return 0.19
                
            // Recording size.
            case .recording(let recordingStatus):
                switch recordingStatus {
                
                // Started recording.
                case .started:
                    return UserSettings.Video.useCamera ? 0.29 : 0.19
                
                // All other recording statuses.
                default:
                    return 0.19
                }
                
            // Consuming size.
            case .consuming(let message, let consumingStatus):
                switch consumingStatus {
                
                // Started consuming.
                case .started:
                    return message.isVideo ? 0.29 : 0.19
                
                // All other recording statuses.
                default:
                    return 0.19
                }
            }
        }

        // Timing function to use for all channel window animations.
        static let timingFunction = CAMediaTimingFunction(controlPoints: 0.215, 0.61, 0.355, 1.0)
    }
    
    // Artificial timing durations used in various places for better UX.
    enum ArtificialTiming {
 
        // How long to show the video recording loading spinner.
        static let showVideoRecordingInitializingDuration = 0.5
        
        // Minimum duration to show the spinner while sending a recording.
        static let showRecordingSendingDuration = 1.2
        
        // How long to show window in the recording-sent state before reverting back to idle state.
        static let showRecordingSentDuration = 0.9
    }
    
    // Get delegate as channel window controller type.
    weak var channelWindowController: ChannelWindowController? { delegate as? ChannelWindowController }
    
    // Get content view controller as channel view controller.
    var channelViewController: ChannelViewController { contentViewController as! ChannelViewController }
        
    // Whether window should respond to interaction.
    var isDisabled = false {
        didSet {
            if isDisabled != oldValue {
                isDisabledChanged()
            }
        }
    }
    
    // Flag indicating whether mouse is inside window.
    var isMouseInside = false
    
    // Check if the given point is located inside of this window's frame.
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
    
    // Bubble up event to controller.
    func onAvatarClick() {
        channelWindowController?.onAvatarClick()
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
    
    // Handler for when isDisabled value changed.
    private func isDisabledChanged() {
        channelViewController.isDisabledChanged(to: isDisabled)
    }

    // Render channel view content.
    func renderContent(_ spec: ChannelRenderSpec, _ state: ChannelState) {
        channelViewController.render(spec, state)
    }
    
    // Render window frame.
    func renderFrame(_ spec: ChannelRenderSpec) {
        updateFrame(size: spec.size, position: spec.position)
    }
    
    // Render window to size/position.
    func render(_ spec: ChannelRenderSpec, _ state: ChannelState) {
        // Store latest disability info on window.
        isDisabled = spec.isDisabled

        // Render frame.
        renderFrame(spec)
        
        // Render content.
        renderContent(spec, state)
    }
}

struct AdjacentChannelOffset {
    var above: Float = 0
    var below: Float = 0
}
