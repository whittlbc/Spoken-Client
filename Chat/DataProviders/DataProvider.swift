//
//  DataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Cache
import Networking
import Combine

class DataProvider<T: Model & NetworkingJSONDecodable> {
            
    private let cache: CodableCache<T> = CacheManager.newCodableCache(T.self)
    
    func get(id: String) -> AnyPublisher<T, Error> {
        // Get result from cache if it exists.
        if let result = cache.get(forKey: id) {
            return Just(result)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Create a new vendor request for the result.
        let request: AnyPublisher<T, Error> = api.get(getNsp(), params: ["id": id])
                
        // Vend, cache, and publish the result.
        return request
            .handleEvents(receiveOutput: { [weak self] result in
                self?.cacheResult(result)
            })
            .eraseToAnyPublisher()
    }
    
    func getFor(for id: String) -> AnyPublisher<T, Error> { get(id: id) }
    
    func cacheResult(_ result: T) {
        do {
            try cache.set(result, forKey: result.id)
        } catch CacheError.writeFailed(key: let key) {
            logger.error("Error caching \(T.modelName) at key \(key).")
        } catch {
            logger.error("Unknown error while caching \(T.modelName)")
        }
    }
    
    private func getNsp(plural: Bool = false) -> String {
        Path.join([plural ? T.modelName.asPlural() : T.modelName], addRoot: true)
    }
    
//    func get(id: String, then provide: @escaping ProvideOne) {
//        if let result = cache.get(forKey: id) {
//            provide(result, nil)
//            return
//        }
//
//        vendOne(params: ["id": id]) { [weak self] result, error in
//            // Handle any vending errors.
//            if let err = error {
//                provide(nil, err)
//                return
//            }
//
//            // If no result is returned, just return empty.
//            guard let res = result else {
//                provide(nil, nil)
//                return
//            }
//
//            // Cache result.
////            self?.cacheResult(res, forKey: id)
//
//            // Provide result.
//            provide(res, nil)
//        }
//    }
//
//    func list(ids: [String], then provide: @escaping ProvideMultiple) {
//        var itemsById = [String: T]()
//        var idsToVend = [String]()
//
//        // Get cached items and populate a list of ids for items needing vending.
//        for id in ids {
//            if let result = cache.get(forKey: id) {
//                itemsById[id] = result
//            } else {
//                idsToVend.append(id)
//            }
//        }
//
//        // If no items need vending, provide items returned from cache in order of given ids.
//        if idsToVend.isEmpty {
//            provide(itemsById.listValues(forKeys: ids), nil)
//            return
//        }
//
//        // Vend items that weren't found in cache.
//        vendMultiple(params: ["ids": idsToVend]) { [weak self] result, error in
//            // Handle any vending errors.
//            if let err = error {
//                provide(nil, err)
//                return
//            }
//
//            // If no result is returned, just return empty.
//            guard let res = result else {
//                provide(nil, nil)
//                return
//            }
//
//            // For each item returned...
//            for item in res {
//                // Cache item by id.
////                self?.cacheResult(item, forKey: item.id)
//
//                // Add item to map by id.
//                itemsById[item.id] = item
//            }
//
//            // Provide list of items in order of ids originally given.
//            provide(itemsById.listValues(forKeys: ids), nil)
//        }
//    }
//

//
//    private func vendOne(params: Params, then handler: @escaping ProvideOne) {
//        let request: AnyPublisher<T, Error> = api.get(vendorNamespace, params: params)
//
//        request.sink(receiveCompletion: { status in
//            switch status {
//
//            case .failure(let error):
//                logger.error("\(error)")
//                handler(nil, .vendingFailed)
//
//            default:
//                break
//            }
//        }, receiveValue: { result in
//            handler(result, nil)
//        }).store(in: &vendorRequests)
//    }
//
//    private func vendMultiple(params: Params, then handler: @escaping ProvideMultiple) {
//        let request: AnyPublisher<[T], Error> = api.get(pluralVendorNamespace, params: params)
//
//        request.sink(receiveCompletion: { status in
//            switch status {
//
//            case .failure(let error):
//                logger.error("\(error)")
//                handler(nil, .vendingFailed)
//
//            default:
//                break
//            }
//        }, receiveValue: { result in
//            handler(result, nil)
//        }).store(in: &vendorRequests)
//    }
}

public enum dataProvider {
    
    static let user = UserDataProvider<User>()
    
    static let workspace = WorkspaceDataProvider<Workspace>()
    
    static let channel = DataProvider<Channel>()
    
    static let member = DataProvider<Member>()
}

//dataProvider.user.publisher.get(id: "a").sink { user, error
//
//}


//dataProvider.user.get(id: "a").workspaces()
