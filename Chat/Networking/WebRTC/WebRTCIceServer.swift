//
//  WebRTCIceServer.swift
//  Chat
//
//  Created by Ben Whittle on 3/16/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

struct WebRTCIceServer: Codable {
    
    var url: String
    
    var username: String?
    
    var credential: String?
    
    func toIceServer() -> RTCIceServer {
        if let username = username, let credential = credential {
            return RTCIceServer(urlStrings: [url], username: username, credential: credential)
        }
        
        return RTCIceServer(urlStrings: [url])
    }
}
