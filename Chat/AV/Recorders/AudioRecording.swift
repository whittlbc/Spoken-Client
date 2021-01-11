//
//  AudioRecording.swift
//  Chat
//
//  Created by Ben Whittle on 1/8/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class AudioRecording {
    
    var data = NSMutableData()
    
    func append(_ audioPCMBuffer: AVAudioPCMBuffer) {
        // TODO: Convert to FLAC and append to data (NSMutableData)
    }
}
