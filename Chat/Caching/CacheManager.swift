//
//  CacheManager.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Cache

// Cache manager and creator.
public enum CacheManager {

    enum CacheName {
        static let string = "string"
        static let image = "image"
    }
    
    // Create a new codable cache.
    static func newCodableCache<T: Codable>(
        _ value: T.Type,
        name: String = "default",
        countLimit: UInt = 0,
        totalCostLimit: UInt = 0) -> CodableCache<T> {
        do {
            let storage: Storage<String, T> = try Storage(
                diskConfig: DiskConfig(name: name),
                memoryConfig: MemoryConfig(countLimit: countLimit, totalCostLimit: totalCostLimit),
                transformer: TransformerFactory.forCodable(ofType: value)
            )
            
            return CodableCache<T>(storage: storage)
        } catch {
            fatalError("Failed to create new codable cache for type \(value): \(error)")
        }
    }
    
    // Create a new image cache.
    static func newImageCache(name: String = CacheName.image, countLimit: UInt = 0, totalCostLimit: UInt = 0) -> ImageCache {
        do {
            let storage: Storage<String, Image> = try Storage(
                diskConfig: DiskConfig(name: CacheName.image),
                memoryConfig: MemoryConfig(countLimit: countLimit, totalCostLimit: totalCostLimit),
                transformer: TransformerFactory.forImage()
            )
            
            return ImageCache(storage: storage)
        } catch {
            fatalError("Failed to create new image cache: \(error)")
        }
    }

    // Global String:String cache.
    static let stringCache: CodableCache<String> = CacheManager.newCodableCache(String.self, name: CacheName.string)
    
    // Global String:Image cache.
    static let imageCache: ImageCache = CacheManager.newImageCache(countLimit: 50)
}
