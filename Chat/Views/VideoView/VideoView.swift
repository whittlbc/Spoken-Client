//
//  VideoView.swift
//  Chat
//
//  Created by Ben Whittle on 3/31/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

class VideoView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // Setup view layer.
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer?.masksToBounds = true
    }
}
