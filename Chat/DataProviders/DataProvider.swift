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

    let cache: CodableCache<T>

    init(cacheCountLimit: UInt = 0) {
        self.cache = CacheManager.newCodableCache(T.self, name: T.modelName, countLimit: cacheCountLimit)
    }
    
    func get(id: String) -> AnyPublisher<T, Error> {
        // Get result from cache if it exists.
        if let result = cache.get(forKey: id) {
            return Just(result)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Create a new vendor request to get this resource by id.
        let request: AnyPublisher<T, Error> = api.get(getNsp(), params: ["id": id])

        // Vend, cache, and publish the result.
        return request
            .mapError(vendorErrorToDataProviderError)
            .handleEvents(receiveOutput: { [weak self] result in
                self?.cacheResult(result)
            })
            .eraseToAnyPublisher()
    }
        
    func list(ids: [String]) -> AnyPublisher<[T], Error> {
        var itemsFromCache = [T]()
        var idsToVend = [String]()

       // Get cached items and populate a list of ids for items needing vending.
        for id in ids {
            if let result = cache.get(forKey: id) {
                itemsFromCache.append(result)
            } else {
                idsToVend.append(id)
            }
        }

        // Just return items from cache if all were found there.
        if idsToVend.isEmpty {
            return Just(itemsFromCache)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        let idsToVendSet = Set(idsToVend)
                
        // Create a new vendor request to get list of resources by ids.
        let request: AnyPublisher<[T], Error> = api.get(
            getNsp(plural: true),
            params: ["ids": idsToVend.joined(separator: ",")]
        )
                    
        // Vend, cache, and publish the results.
        return request
            .mapError(vendorErrorToDataProviderError)
            .append(itemsFromCache)
            .sortBy(ids: ids)
            .handleEvents(receiveOutput: { [weak self] results in
                for result in results where idsToVendSet.contains(result.id) {
                    self?.cacheResult(result)
                }
            })
            .eraseToAnyPublisher()
    }
    
    func create(params: Params) -> AnyPublisher<T, Error> {
        // Create a new vendor request to create this resource with the given params..
        let request: AnyPublisher<T, Error> = api.post(getNsp(), params: params)

        // Create, cache, and publish the result.
        return request
            .mapError(vendorErrorToDataProviderError)
            .handleEvents(receiveOutput: { [weak self] result in
                self?.cacheResult(result)
            })
            .eraseToAnyPublisher()
    }
    
    func patch(_ suffix: String, params: Params) -> AnyPublisher<T, Error> {
        // Create a new vendor request to patch this resource with the following params.
        let request: AnyPublisher<T, Error> = api.patch(getNsp() + suffix, params: params)

        // Patch, cache, and publish the result.
        return request
            .mapError(vendorErrorToDataProviderError)
            .handleEvents(receiveOutput: { [weak self] result in
                self?.cacheResult(result)
            })
            .eraseToAnyPublisher()
    }
    
    func cacheResult(_ result: T) {
        do {
            try cache.set(result.forCache(), forKey: result.id)
        } catch CacheError.writeFailed(key: let key) {
            logger.error("Error caching \(T.modelName) at key \(key).")
        } catch {
            logger.error("Unknown error while caching \(T.modelName)")
        }
    }
    
    private func getNsp(plural: Bool = false) -> String {
        Path.join([plural ? T.modelName.asPlural() : T.modelName], addRoot: true)
    }
        
    func vendorErrorToDataProviderError(for error: Error) -> Error {
        guard let err = error as? NetworkingError else {
            logger.error("Vendor returned unknown error: \(error).")
            return DataProviderError.unknown
        }
        
        logger.error("Vendor returned error: status=\(err.status), code=\(err.code)")
        
        switch err.status {
        
        case .notFound:
            return DataProviderError.notFound
            
        case .badRequest:
            return DataProviderError.invalidInput
            
        case .unauthorized:
            return DataProviderError.unauthorized
            
        case .forbidden:
            return DataProviderError.forbidden
            
        case .internalServerError:
            return DataProviderError.internalServerError
            
        default:
            return DataProviderError.unknown
        }
    }
    
    func imageErrorToDataProviderError(for error: Error) -> Error {
        guard let err = error as? ImageError else {
            return DataProviderError.unknown
        }
                
        switch err {
        
        case .invalidURL:
            return DataProviderError.invalidURL
            
        case .requestFailed:
            return DataProviderError.badImage
        }
    }
}

public enum dataProvider {
    
    static let user = UserDataProvider<User>()
    
    static let workspace = WorkspaceDataProvider<Workspace>()
    
    static let channel = ChannelDataProvider<Channel>()
    
    static let member = MemberDataProvider<Member>()
    
    static let message = MessageDataProvider<Message>()
    
    static let file = FileDataProvider<File>()
}
