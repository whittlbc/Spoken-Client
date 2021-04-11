//
//  VideoPlayerView.swift
//  Chat
//
//  Created by Ben Whittle on 4/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import AVKit

class VideoPlayerView: NSView {
    
    var playerLayer: AVPlayerLayer!
    
    private var playerLayerContext = 0
    
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
        layer?.backgroundColor = CGColor.clear
        addPlayerLayer()
    }
    
    private func addPlayerLayer() {
        playerLayer = AVPlayerLayer(player: AV.getMessagePlayer()!)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
        playerLayer.backgroundColor = CGColor.clear
        layer?.addSublayer(playerLayer)
    }
    
    override func layout() {
        layer?.frame = bounds
        playerLayer.frame = bounds
    }
}
