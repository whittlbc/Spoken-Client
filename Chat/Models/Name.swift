//
//  Name.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct Name: Model {

    static var modelName = "name"

    var id = ""
    var first = ""
    var last = ""

    func forCache() -> Name {
        self
    }
}
