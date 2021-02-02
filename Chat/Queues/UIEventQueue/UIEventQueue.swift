//
//  UIQueue.swift
//  Chat
//
//  Created by Ben Whittle on 2/1/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public let uiEventQueue = Queue<UIEvent>(
    name: "ui-event-queue",
    threadName: "ui-events"
)
