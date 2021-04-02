//
//  UIEvent.swift
//  Chat
//
//  Created by Ben Whittle on 2/1/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

enum UIEvent {
    case newIncomingMessage(message: Message, cookies: [String: String])
}
