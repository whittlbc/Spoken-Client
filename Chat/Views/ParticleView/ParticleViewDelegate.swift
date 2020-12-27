//
//  ParticleViewDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 12/27/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

protocol ParticleViewDelegate: NSObjectProtocol {
    
    func particleViewDidUpdate()
    
    func particleViewMetalUnavailable()
}
