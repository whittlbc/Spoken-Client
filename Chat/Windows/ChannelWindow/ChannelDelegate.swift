//
//  ChannelDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

protocol ChannelDelegate: NSObjectProtocol {
    
    func onChannelsRequireGroupUpdate(activeChannelId: String)
}

