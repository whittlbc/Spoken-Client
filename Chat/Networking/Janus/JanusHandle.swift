//
//  JanusHandle.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

typealias JanusHandleBlock = (JanusHandle?) -> Void

typealias JanusRemoteJSEPBlock = (JanusHandle?, [AnyHashable : Any]?) -> Void

class JanusHandle {
    
    var handleId: Int?
    
    var feedId: Int?
    
    var display: String?
    
    var onJoined: JanusHandleBlock?
    
    var onRemoteJSEP: JanusRemoteJSEPBlock?
    
    var onLeaving: JanusHandleBlock?
}
