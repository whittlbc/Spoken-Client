////
////  Cache+Ids.swift
////  Chat
////
////  Created by Ben Whittle on 12/11/20.
////  Copyright © 2020 Ben Whittle. All rights reserved.
////
//
//import Foundation
//import Cache
//
//extension Cache {
//
//    // Ids cache
//    enum Ids {
//
//        // Storage instance.
//        static let storage: Storage<String, [String]> = Cache.newStorage([String].self)
//
//        // Standardized user cache keys.
//        enum Keys {
//            static let workspaces = "workspaces"
//        }
//
//        // Set workspaces.
//        static func setWorkspaces(ids: [String]) {
//            do {
//                try Ids.storage.setObject(ids, forKey: Keys.workspaces)
//            } catch {
//                logger.error("Error setting workspace ids in Ids cache: \(error)")
//            }
//        }
//    }
//}
