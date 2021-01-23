//
//  ChannelView.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Content view of channel window.
class ChannelView: NSView {
    
    // Channel view styling information.
    enum Style {
        
        // Opacity of view when disabled.
        static let disabledOpacity: CGFloat = 0.25
    }
    
    // Get this view's window as a channel window instance.
    weak var channelWindow: ChannelWindow? { window as? ChannelWindow }

    // Allow this view to be the first responder in the chain to key events.
    override var acceptsFirstResponder: Bool { true }
    
    // Allow the first click into this view to be "heard", event if the window itself isn't active at the time of click.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    
    // This view's size should always fill the entire contents of its window.
    override func layout() {
        super.layout()
        frame = bounds
    }

    // Add a tracking area that takes up the entirete of this view and listens for important mouse events.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Remove any old tracking areas.
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        // Always listen for mouse enter and exit events, regardless of window active status.
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        
        // Create latest tracking area.
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        // Add lastest tracking area.
        addTrackingArea(trackingArea)
    }

    // Bubble up event to channel window.
    func onAvatarClick() {
        channelWindow?.onAvatarClick()
    }
}
