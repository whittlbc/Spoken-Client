//
//  RoundView.swift
//  Chat
//
//  Created by Ben Whittle on 12/13/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// NSView with corner radius of 50% that works with auto-layout.
class RoundView: NSView {
    
    // Update corner radius to 50% on every call to layout
    override func layout() {
        super.layout()
        
        // Make view layer-based.
        wantsLayer = true
        
        // Set corner radius to 50%
        layer?.cornerRadius = bounds.height / 2
    }
}
