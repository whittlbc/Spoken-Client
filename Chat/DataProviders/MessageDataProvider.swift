//
//  MessageDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class MessageDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {
    
    convenience init() {
        self.init(cacheCountLimit: 200)
    }
    
    override init(cacheCountLimit: UInt = 0) {
        super.init(cacheCountLimit: cacheCountLimit)
    }
    
    func create(channelId: String, messageType: MessageType) -> AnyPublisher<T, Error> {
        create(params: ["channel_id": channelId, "message_type": messageType.rawValue])
    }
    
    func getForConsumption(id: String) -> AnyPublisher<T, Error> {
        return get(id: id)
            .flatMap({ self.loadFiles(for: $0, forConsumption: true) })
            .eraseToAnyPublisher()
    }
    
    private func loadFiles(for model: T, forConsumption: Bool = false) -> AnyPublisher<T, Error> {
        var message = model as! Message
        
        return publishedFileIds(message: message)
            .flatMap {
                Publishers.MergeMany(
                    $0.map({ dataProvider.file.get(id: $0, params: ["for_consumption": true]) })
                )
            }
            .collect()
            .map { files in
                message.files = files
                return message as! T
            }
            .eraseToAnyPublisher()
    }
    
    private func publishedFileIds(message: Message) -> AnyPublisher<[String], Error> {
        return Just(message.fileIds)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
