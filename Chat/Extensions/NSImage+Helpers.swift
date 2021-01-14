//
//  NSImage+Load.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

extension NSImage {
    
    static func forKey(_ key: String, remoteURL: String, then handler: @escaping (NSImage?) -> Void) {
        // Attempt to get an image from the image cache for the provided key.
        if let image = CacheManager.imageCache.get(forKey: key) {
            handler(image)
            return
        }

        // Create a url object from string.
        guard let url = URL(string: remoteURL) else {
            logger.error("Invalid creation of URL from string(\(remoteURL) while fetching NSImage for key \(key).")
            handler(nil)
            return
        }
        
        // Fetch image from remote URL.
        let image = NSImage(byReferencing: url)
        
        // Cache image for given key.
        try? CacheManager.imageCache.set(image, forKey: key)
        
        // Return the image.
        handler(image)
    }
}

