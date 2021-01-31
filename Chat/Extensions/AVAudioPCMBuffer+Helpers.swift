//
//  AVAudioPCMBuffer+Helpers.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioPCMBuffer {
    
    func asData() -> Data {
        let channels = UnsafeBufferPointer(start: floatChannelData, count: 1)
        return NSData(bytes: channels[0], length: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame)) as Data
    }
}
