//
//  Thread.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum Thread {
    
    static func newBackgroundThread(name: String) -> DispatchQueue {
        dispatch_queue_global_t(
            label: [Config.appBundleID, name].joined(separator: "."),
            qos: .background
        )
    }
}
