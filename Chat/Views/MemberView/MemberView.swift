//
//  MemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberView: NSView {
//
//    // Proper initializer to use when rendering member.
//    convenience init() {
//        self.init(frame: NSZeroRect)
//    }
//
//    // Override delgated init.
//    private override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        frame = bounds
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)

        addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        print("DOWN")
    }
}
