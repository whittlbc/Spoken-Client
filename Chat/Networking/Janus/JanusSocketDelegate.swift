//
//  JanusSocketDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

protocol JanusSocketDelegate: NSObjectProtocol {

    func onPublisherJoined(_ handleId: Int?)
    
    func onPublisherRemoteJSEP(_ handleId: Int?, dict jsep: [AnyHashable : Any]?)
    
    func subscriberHandleRemoteJSEP(_ handleId: Int?, dict jsep: [AnyHashable : Any]?)
    
    func onLeaving(_ handleId: Int?)
}
