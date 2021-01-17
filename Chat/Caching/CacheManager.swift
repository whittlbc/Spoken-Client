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
    
    // On-Disk storage configuration
    private static let diskConfig = DiskConfig(name: Config.appBundleID)

    // In-memory storage configuration.
    private static let memoryConfig = MemoryConfig()

    // Create a new codable cache.
    static func newCodableCache<T: Codable>(_ value: T.Type, name: String = "default") -> CodableCache<T> {
        do {
            let storage: Storage<String, T> = try Storage(
                diskConfig: DiskConfig(name: name),
                memoryConfig: MemoryConfig(),
                transformer: TransformerFactory.forCodable(ofType: value)
            )
            
            return CodableCache<T>(storage: storage)
        } catch {
            fatalError("Failed to create new codable cache for type \(value): \(error)")
        }
    }
    
    // Create a new image cache.
    static func newImageCache(name: String = CacheName.image) -> ImageCache {
        do {
            let storage: Storage<String, Image> = try Storage(
                diskConfig: DiskConfig(name: CacheName.image),
                memoryConfig: MemoryConfig(),
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
    static let imageCache: ImageCache = CacheManager.newImageCache()
}
