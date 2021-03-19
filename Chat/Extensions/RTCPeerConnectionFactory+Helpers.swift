//
//  RTCPeerConnectionFactory.swift
//  Chat
//
//  Created by Ben Whittle on 2/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

extension RTCPeerConnectionFactory {
    
    static func newDefaultFactory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
                
        // Support all codec formats for encode and decode.
        return RTCPeerConnectionFactory(
            encoderFactory: RTCDefaultVideoEncoderFactory(),
            decoderFactory: RTCDefaultVideoDecoderFactory()
        )
    }
}
