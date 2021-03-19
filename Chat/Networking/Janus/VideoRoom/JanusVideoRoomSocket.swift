//
//  JanusVideoRoomSocket.swift
//  Chat
//
//  Created by Ben Whittle on 3/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC
import Arrow

class JanusVideoRoomSocket: JanusSocket {
    
    // Id of Janus room to connect to.
    var roomId: Int!
    
    convenience init(url: String, roomId: Int) {
        self.init(url: url, headers: JanusSocket.defaultHeaders)
        
        // Set video room id to connect to.
        self.roomId = roomId

        // Set plugin to videoroom.
        self.plugin = JanusMessage.Key.videoRoomPlugin
    }
    
    override init(url: String, headers: [String: String] = [:], requestTimeoutInterval: TimeInterval = 5) {
        super.init(url: url, headers: headers, requestTimeoutInterval: requestTimeoutInterval)
    }
                
    override func sendOffer(handleId: Int, sdp: RTCSessionDescription) {
        sendMessage(JanusVideoRoomPublisherOfferMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            jsep: JanusJSEP(sdp: sdp),
            requestType: .configure,
            audio: true,
            video: true
        ))
    }
    
    override func sendAnswer(handleId: Int, sdp: RTCSessionDescription) {
        sendMessage(JanusVideoRoomSubscriberAnswerMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            jsep: JanusJSEP(sdp: sdp),
            requestType: .start,
            room: roomId
        ))
    }
    
    override func onEventMessage(_ json: JSON) {
        // Create videoroom event message from json.
        let message = JanusVideoRoomEventMessage.fromJSON(json)
        
        // If new videoroom handle joined, register it as having joined.
        if message.handleDidJoin {
            onHandleJoined(message: message)
        }
        
        // If any new remote publishers exist, subscribe to them.
        if message.hasPublishers {
            onPublishersAvailable(message.publishers)
        }
        
        // If videoroom handle left, register it as having left.
        if message.feedDidLeave {
            onLeavingFeed(withId: message.leavingFeedId)
        }
        
        // Handle remote JSEP if provided.
        if message.hasJSEP {
            onRemoteJSEP(message: message)
        }
    }
    
    override func onAttachedToPlugin(handleId: Int) {
        // Create new handle for publisher.
        let handle = createHandle(
            id: handleId,
            onRemoteJSEP: { [weak self] jsep in
                self?.delegate?.onPublisherRemoteJSEP(handleId: handleId, jsep: jsep)
            },
            onJoined: { [weak self] in
                self?.delegate?.onPublisherJoined(handleId: handleId)
            }
        )

        // Join room as publisher.
        joinRoom(as: .publisher, handle: handle)
    }
    
    private func joinRoom(as ptype: JanusJoinRoomMessageBody.PType, handle: JanusHandle) {
        // Create new transaction to join room.
        let tx = createTx(
            onSuccess: { [weak self] _ in
                self?.onJoinedRoomSuccess(as: ptype)
            },
            onError: { [weak self] message in
                self?.onJoinedRoomError(message)
            }
        )
        
        // Send message requesting to join room.
        sendMessage(JanusJoinRoomMessage(
            sessionId: sessionId!,
            handleId: handle.id,
            txId: tx.id,
            requestType: .join,
            room: roomId,
            ptype: ptype,
            feed: handle.feedId
        ))
    }
    
    private func onHandleJoined(message: JanusVideoRoomEventMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus handle joined videoroom but no handle found for id: \(message.sender) -- \(message)")
            return
        }
        
        // Call handle leaving block.
        handle.onJoined?()
    }
        
    private func onRemoteJSEP(message: JanusVideoRoomEventMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus handle onRemoteJSEP but no handle found for id: \(message.sender) -- \(message)")
            return
        }
        
        // Call remote JSEP block.
        handle.onRemoteJSEP(message.jsep)
    }
    
    private func onPublishersAvailable(_ publishers: [JanusVideoRoomEventMessagePluginPublisher]) {
        for publisher in publishers where publisher.hasFeed {
            attachToPlugin { [weak self] message in
                self?.onSubscriberHandleCreationSuccess(message, publisher: publisher)
            }
        }
    }
    
    private func onLeavingFeed(withId feedId: Int) {
        // Get feed by id.
        guard let feed = feeds[feedId] else {
            logger.warning("Janus feed leaving handler: No feed found for id: \(feedId)")
            return
        }
        
        // Call feed leaving block.
        feed.onLeaving?()
    }
                
    private func onSubscriberHandleCreationSuccess(
        _ message: JanusTxResponseMessage,
        publisher: JanusVideoRoomEventMessagePluginPublisher
    ) {
        // Get handle id from message data.
        guard message.hasDataId else {
            logger.error("Janus handle creation succeeded but id returned was empty...\(message)")
            return
        }
        
        // Get handle id from message.
        let handleId = message.dataId
        
        // Get feed id from publisher.
        let feedId = publisher.feedId
        
        // Create new handle for subscriber.
        let handle = createHandle(
            id: message.dataId,
            onRemoteJSEP: { [weak self] jsep in
                self?.delegate?.onSubscriberRemoteJSEP(handleId: handleId, jsep: jsep)
            },
            feedId: feedId,
            onLeaving: { [weak self] in
                self?.onSubscriberLeaving(handleId: handleId, feedId: feedId)
            }
        )
        
        // Register handle as a feed.
        feeds[feedId] = handle
        
        // Join room as subscriber.
        joinRoom(as: .listener, handle: handle)
    }
    
    private func onSubscriberLeaving(handleId: Int, feedId: Int) {
        // Create new transaction to create a new handle.
        let tx = createTx(
            onSuccess: { [weak self] message in
                self?.onSubscriberLeavingSuccess(handleId: handleId, feedId: feedId)
            },
            onError: { [weak self] message in
                self?.onSubscriberLeavingError(message)
            }
        )
        
        // Send message to Janus.
        sendMessage(JanusLeaveMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: tx.id
        ))
    }
    
    private func onSubscriberLeavingSuccess(handleId: Int, feedId: Int) {
        delegate?.onSubscriberLeaving(handleId: handleId)
        
        handles.removeValue(forKey: handleId)
        
        if feedId != 0 {
            feeds.removeValue(forKey: feedId)
        }
    }
    
    private func onJoinedRoomSuccess(as ptype: JanusJoinRoomMessageBody.PType) {
        logger.info("Successfully joined room as \(ptype.rawValue)")
        // You should have a response message.data which will be your publisher id
    }
    
    private func onJoinedRoomError(_ message: JanusTxResponseMessage) {
        logger.error("Janus failed to join room: code=\(message.error.code), reason=\(message.error.reason).")
    }
    
    private func onSubscriberLeavingError(_ message: JanusTxResponseMessage) {
        logger.error("Janus failed to leave as subscriber: code=\(message.error.code), reason=\(message.error.reason).")
    }
}
