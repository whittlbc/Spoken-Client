//
//  Path.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

enum Path {
        
    static var tempDir: URL {
        NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
    }
    
    static func join(_ comps: [String], addRoot: Bool = false) -> String {
        let path = comps.joined(separator: "/")
        return addRoot ? "/\(path)" : path
    }

    static func size(_ url: URL) -> Int? {
        do {
            let resources = try url.resourceValues(forKeys:[.fileSizeKey])
            return resources.fileSize!
        } catch {
            return nil
        }
    }
}
