//
//  UIEvent.swift
//  Chat
//
//  Created by Ben Whittle on 2/1/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public struct UIEventWrapper {
    let context: UIEventContext
    let event: UIEvent
}

public enum UIEventContext {
    case workspace(id: String)
}

public enum UIEvent {
    case newIncomingMessage(channelId: String, messageId: String)
}
