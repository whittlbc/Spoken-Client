//
//  RTCVideoFrame+Image.swift
//  Chat
//
//  Created by Ben Whittle on 2/14/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

import Foundation
import WebRTC

extension RTCVideoFrame {
    
    var ciImage: CIImage? {
        guard let buffer = self.buffer as? RTCCVPixelBuffer else {
            return nil
        }

        return CIImage(cvImageBuffer: buffer.pixelBuffer)
    }
    
    var nsImage: NSImage? { ciImage?.nsImage }
}
