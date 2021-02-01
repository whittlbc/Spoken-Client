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
    
    let fileName = UUID().uuidString
    
    let fileExt = "flac"
        
    var filePath: URL { Path.tempDir.appendingPathComponent(fileName).appendingPathExtension(fileExt) }
        
    var size: Int { Path.size(filePath) ?? 0 }

    private var stream: OutputStream?
    
    init() {
        createStream()
    }

    func append(_ data: Data) {
        stream?.write(data: data)
    }
    
    func finish() {
        stream?.close()
    }
    
    private func createStream() {
        stream = OutputStream(url: filePath, append: true)
        stream?.open()
    }
}
