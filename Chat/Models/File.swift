//
//  File.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

enum FileType: String {
    case flac
}

enum FileUploadStatus: String {
    case pending
    case succeeded
    case failed
}

struct File: Model {
    
    static var modelName = "file"

    var id = ""
    var externalId = ""
    var fileType = ""
    var name = ""
    var ext = ""
    var size: Int = 0
    var uploadStatus = ""
    var uploadURLs = [String]()
    var downloadURL = ""
    
    var mimeType: String {
        switch FileType(rawValue: fileType) {
        case .flac:
            return "audio/x-flac"
        default:
            return ""
        }
    }
    
    func forCache() -> File {
        var file = self
        file.uploadURLs.removeAll()
        file.downloadURL = ""
        return file
    }
}
