//
//  PubsubManager.swift
//  Chat
//
//  Created by Ben Whittle on 4/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import PubNub
import Arrow

class PubsubManager {
    
    var client: PubNub!
    
    var listener: SubscriptionListener!
    
    var channels: [String] {
        ["member:abc"]
    }
    
    func start() {
        // Create new pubsub client.
        initializeClient()
        
        // Create listener.
        createListener()
        
        // Subscribe to channels.
        subscribe()
    }
    
    func subscribe() {
        client.subscribe(to: channels, withPresence: true)
    }
    
    private func initializeClient() {
        client = PubNub(configuration: PubNubConfiguration(
            publishKey: Config.pubNubPublishKey,
            subscribeKey: Config.pubNubSubscribeKey,
            uuid: Session.currentUserId
        ))
    }
    
    private func createListener() {
        listener = SubscriptionListener()
        
        // Listen for messages.
        listener.didReceiveMessage = { [weak self] message in
            self?.onMessage(message)
        }

        // Listen for presence changes.
        listener.didReceivePresence = { [weak self] change in
            self?.onPresenceChange(change)
        }

        // Listen for subscription changes.
        listener.didReceiveSubscriptionChange = { [weak self] event in
            self?.onSubscriptionChange(event)
        }
        
        // Listen for status changes.
        listener.didReceiveStatus = { event in
            switch event {
            case .success(let connection):
                logger.info("Pubsub status changed to \(connection)")
            case .failure(let error):
                logger.error("Pubsub status error: \(error.localizedDescription)")
            }
        }

        // Register listener to client.
        client.add(listener)
    }
        
    private func onMessage(_ message: PubNubMessage) {
        // Extract event name and data from message payload.
        guard let event = message.payload.codableValue["event"],
              let eventStr = event.stringOptional,
              let eventName = PubsubEvent.Name(rawValue: eventStr),
              let data = message.payload.codableValue["data"],
              let json = JSON(data.jsonData) else {
            return
        }
        
        switch eventName {
        
        // New Message
        case .newMessage:
            onNewMessageEvent(NewMessageEvent.fromJSON(json))
        }
    }

    private func onNewMessageEvent(_ event: NewMessageEvent) {
        uiEventQueue.addItem(UIEvent.newIncomingMessage(message: event.message))
    }
    
    private func onPresenceChange(_ event: PubNubPresenceChange) {
        let action = event.metadata?.codableValue["pn_action"]
        logger.info("Pubsub presence changed: channel=\(event.channel), action=\(action ?? "")")
    }
    
    private func onSubscriptionChange(_ event: SubscriptionChangeEvent) {
        switch event {
        
        // On subscribed to channels.
        case .subscribed(let channels, _):
            logger.info("Subscribed to new channels: \(channels.map(\.id).joined(separator: ", "))")
            
        default:
            break
        }
    }
}

let pubsubManager = PubsubManager()
