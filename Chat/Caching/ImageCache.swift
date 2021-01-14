//
//  ImageCache.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Cache

class ImageCache {

    let storage: Storage<String, Image>
    
    init(storage: Storage<String, Image>) {
        self.storage = storage
    }

    func get(forKey key: String) -> Image? {
        try? storage.object(forKey: key)
    }

    func set(_ object: Image, forKey key: String) throws {
        do {
            try storage.setObject(object, forKey: key)
        } catch {
            logger.error("\(error)")
            throw CacheError.writeFailed(key: key)
        }
    }
}
