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
    
    var data = Data()

    func append(_ data: Data) {
        self.data.append(data)
    }
}
