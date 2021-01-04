//
//  Channel.swift
//  Chat
//
//  Created by Ben Whittle on 1/3/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

struct Channel: Identifiable, Codable {
    var id = ""
    var members = [Member]()
}
