//
//  Member.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct Member: Identifiable, Codable {
    var uid = ""
    var user = User()
}
