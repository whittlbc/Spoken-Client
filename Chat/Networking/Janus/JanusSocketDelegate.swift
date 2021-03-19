//
//  JanusVideoRoomSocketDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

protocol JanusSocketDelegate: NSObjectProtocol {

    func onPublisherJoined(handleId: Int)
    
    func onPublisherRemoteJSEP(handleId: Int, jsep: JanusJSEP?)
    
    func onSubscriberRemoteJSEP(handleId: Int, jsep: JanusJSEP?)
    
    func onSubscriberLeaving(handleId: Int)
    
    func onSocketError(_ error: Error?)
}
