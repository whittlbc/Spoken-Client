//
//  ChannelWindowModel.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//
import Cocoa
import Combine

class ChannelWindowModel {
    
    typealias MessageResult = Result<Message, Error>
    
    var channel: Channel
    
    @Published private(set) var currentMessage: Message?

    private var currentMessageResult = MessageResult.success(Message()) {
        didSet {
            switch currentMessageResult {
            case .success(let message):
                self.currentMessage = message
            case .failure(_):
                self.currentMessage = nil
            }
        }
    }
        
    private var currentMessageCancellable: AnyCancellable?
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    func createRecordingMessage() {
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + 0.1
    ) {
            var message = Message()
            message.id = "abc123"
            message.channelId = self.channel.id
            message.senderId = "ben"
            message.messageType = "video"
            message.status = "pending"
            message.streamServerIP = "54.177.6.163"
            message.iceServerURLs = [
                WebRTCIceServer(url: "stun:54.153.12.146:3478", username: nil, credential: nil)
            ]
            
            self.currentMessageResult = MessageResult.success(message)
        }
        
//        currentMessageCancellable = dataProvider.message
//            .create(
//                channelId: channel.id,
//                messageType: UserSettings.Video.useCamera ? .video : .audio
//            )
//            .asResult()
//            .sink { [weak self] result in
//                self?.currentMessageResult = result
//            }
    }
    
    func loadMessageForConsumption(withId id: String) {
        currentMessageCancellable = dataProvider.message
            .get(id: id)
            .asResult()
            .sink { [weak self] result in
                self?.currentMessageResult = result
            }
    }
    
    func sendMessageToInbox(withId id: String) {
        // TODO
    }
}
