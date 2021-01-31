//
//  File+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension File: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        id <-- json["id"]
        externalId <-- json["external_id"]
        fileType <-- json["file_type"]
        name <-- json["name"]
        ext <-- json["ext"]
        size <-- json["size"]
        uploadStatus <-- json["upload_status"]
        uploadURLs <-- json["upload_urls"]
    }
}
