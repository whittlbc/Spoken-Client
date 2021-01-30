//
//  File.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

struct File: Model {
    
    static var modelName = "file"

    var id = ""
    var externalId = ""
    var status = ""
    var fileType = ""
    var name = ""
    var ext = ""
    var size: Int = 0
    
    func forCache() -> File {
        self
    }
}
