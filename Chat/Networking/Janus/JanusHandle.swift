//
//  JanusHandle.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

typealias JanusHandleBlock = () -> Void

typealias JanusRemoteJSEPBlock = (JanusJSEP?) -> Void

class JanusHandle {
    
    var id: Int!
    
    var feedId: Int?

    var onJoined: JanusHandleBlock?

    var onLeaving: JanusHandleBlock?
    
    var onRemoteJSEP: JanusRemoteJSEPBlock
    
    init(
        id: Int,
        onRemoteJSEP: @escaping JanusRemoteJSEPBlock,
        feedId: Int? = nil,
        onJoined: JanusHandleBlock? = nil,
        onLeaving: JanusHandleBlock? = nil
    ) {
        self.id = id
        self.onRemoteJSEP = onRemoteJSEP
        self.feedId = feedId
        self.onJoined = onJoined
        self.onLeaving = onLeaving
    }
}
