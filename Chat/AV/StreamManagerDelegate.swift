//
//  StreamManagerDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 4/2/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

protocol StreamManagerDelegate: NSObjectProtocol {
    
    func onVideoPreviewStarted()
}
